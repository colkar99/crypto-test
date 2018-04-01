class WebhooksController < ApplicationController
	before_action :auth_anybody!
	skip_before_filter :verify_authenticity_token
	def tx
		if params[:type] == "transaction" && params[:hash].present?
			AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "satoshi")
			render :json => { :status => "queued" }
		end
	end
	def ltx
		if params[:type] == "transaction" && params[:hash].present?
			AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "litecoin")
			render :json => { :status => "queued" }
		end
	end
	def eth
		if params[:type] == "transaction" && params[:hash].present?
			AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "ether")
			render :json => { :status => "queued" }
		end
	end
	def dtx
		if params[:type] == "transaction" && params[:hash].present?
			AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "dashcoin")
			render :json => { :status => "queued" }
		end
	end
	def bch
		if params[:type] == "transaction" && params[:hash].present?
			AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "bitcoincash")
			render :json => { :status => "queued" }
		end
	end
	def xrp
		if params[:type] == "transaction" && params[:hash].present?
			AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "ripple")
			render :json => { :status => "queued" }
		end
	end
end
