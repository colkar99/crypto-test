module Withdraws
  module Coinable
    extend ActiveSupport::Concern

    def set_fee
      case currency_obj.code
        when "btc"
          self.fee = "0.0001".to_d
        when "dash"
          self.fee = "1".to_d
        when "ltc"
          self.fee = "0.0001".to_d
        when "bch"
          self.fee = "0.0001".to_d
      end
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def audit!
      result = CoinRPC[currency].validateaddress(fund_uid)

      if result.nil? || (result[:isvalid] == false)
        Rails.logger.info "#{self.class.name}##{id} uses invalid address: #{fund_uid.inspect}"
        reject
        save!
      elsif (result[:ismine] == true) || PaymentAddress.find_by_address(fund_uid)
        Rails.logger.info "#{self.class.name}##{id} uses hot wallet address: #{fund_uid.inspect}"
        reject
        save!
      else
        super
      end
    end

    def as_json(options={})
      super(options).merge({
        blockchain_url: blockchain_url
      })
    end

  end
end

