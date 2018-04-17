module Matching
  class Engine

    attr :orderbook, :mode, :queue
    delegate :ask_orders, :bid_orders, to: :orderbook

    def initialize(market, options={})
      @market    = market
      @orderbook = OrderBookManager.new(market.id)

      # Engine is able to run in different mode:
      # dryrun: do the match, do not publish the trades
      # run:    do the match, publish the trades (default)
      shift_gears(options[:mode] || :run)

      Rails.logger.info "Thread initialized!!!"

      if @fake_order_thread
        Rails.logger.info "Thread exit!!!"
        @fake_order_thread.exit
      end
      @fake_order_thread = Thread.new do
        loop do
          sleep 5
          submit_fake_order
        end
      end
    end

    def submit_fake_order
      uri = URI.parse("https://bittrex.com")
      uri.path = "/api/v1.1/public/getorderbook"
      uri.query = "market=#{@market.query_name}&type=buy"
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      response = https.get uri.request_uri
      resp = JSON.parse( response.body )
      if resp['success']
        resp['result'].reverse.each do |f_order|
          @order = OrderBid.find_by_price f_order["Rate"]
          unless @order
            m_order = {:bid => @market.bid['currency'],
                       :ask => @market.ask['currency'],
                       :state => Order::WAIT,
                       :currency => @market.id,
                       :volume => f_order["Quantity"],
                       :origin_volume => f_order["Quantity"],
                       :source => 'Web',
                       :price => f_order["Rate"],
                       :ord_type => 'limit'
            }
            @order = OrderBid.new(m_order)
            # Rails.logger.info "Submitting Order: #{@order.as_json}"
            Ordering.new(@order).submit
          end
        end
      end

      uri = URI.parse("https://bittrex.com")
      uri.path = "/api/v1.1/public/getorderbook"
      uri.query = "market=#{@market.query_name}&type=sell"
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      response = https.get uri.request_uri
      resp = JSON.parse( response.body )
      if resp['success']
        resp['result'].reverse.each do |f_order|
          @order = OrderAsk.find_by_price f_order["Rate"]
          unless @order
            m_order = {:bid => @market.bid['currency'],
                       :ask => @market.ask['currency'],
                       :state => Order::WAIT,
                       :currency => @market.id,
                       :volume => f_order["Quantity"],
                       :origin_volume => f_order["Quantity"],
                       :source => 'Web',
                       :price => f_order["Rate"],
                       :ord_type => 'limit'
            }
            @order = OrderAsk.new(m_order)
            # Rails.logger.info "Submitting Order: #{@order.as_json}"
            Ordering.new(@order).submit
          end
        end
      end
    end

    def submit(order)
      book, counter_book = orderbook.get_books order.type
      match order, counter_book
      add_or_cancel order, book
    rescue
      Rails.logger.fatal "Failed to submit order #{order.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def cancel(order)
      book, counter_book = orderbook.get_books order.type
      if removed_order = book.remove(order)
        publish_cancel removed_order, "cancelled by user"
      else
        Rails.logger.warn "Cannot find order##{order.id} to cancel, skip."
      end
    rescue
      Rails.logger.fatal "Failed to cancel order #{order.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def limit_orders
      { ask: ask_orders.limit_orders,
        bid: bid_orders.limit_orders }
    end

    def market_orders
      { ask: ask_orders.market_orders,
        bid: bid_orders.market_orders }
    end

    def shift_gears(mode)
      case mode
      when :dryrun
        @queue = []
        class <<@queue
          def enqueue(*args)
            push args
          end
        end
      when :run
        @queue = AMQPQueue
      else
        raise "Unrecognized mode: #{mode}"
      end

      @mode = mode
    end

    private

    def match(order, counter_book)
      return if order.filled?

      counter_order = counter_book.top
      return unless counter_order

      if trade = order.trade_with(counter_order, counter_book)
        counter_book.fill_top *trade
        order.fill *trade

        publish order, counter_order, trade

        match order, counter_book
      end
    end

    def add_or_cancel(order, book)
      return if order.filled?
      order.is_a?(LimitOrder) ?
        book.add(order) : publish_cancel(order, "fill or kill market order")
    end

    def publish(order, counter_order, trade)
      ask, bid = order.type == :ask ? [order, counter_order] : [counter_order, order]

      price  = @market.fix_number_precision :bid, trade[0]
      volume = @market.fix_number_precision :ask, trade[1]
      funds  = trade[2]

      Rails.logger.info "[#{@market.id}] new trade - ask: #{ask.label} bid: #{bid.label} price: #{price} volume: #{volume} funds: #{funds}"

      @queue.enqueue(
        :trade_executor,
        {market_id: @market.id, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: volume, funds: funds},
        {persistent: false}
      )
    end

    def publish_cancel(order, reason)
      Rails.logger.info "[#{@market.id}] cancel order ##{order.id} - reason: #{reason}"
      @queue.enqueue(
        :order_processor,
        {action: 'cancel', order: order.attributes},
        {persistent: false}
      )
    end

  end
end
