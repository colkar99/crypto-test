module Private
  class AssetsController < BaseController
    skip_before_action :auth_member!, only: [:index]

    def index
      @btc_proof   = Proof.current :btc
      @eth_proof   = Proof.current :eth
      @bch_proof   = Proof.current :bch
      @dash_proof   = Proof.current :dash
      @ltc_proof   = Proof.current :ltc
      @xrp_proof  = Proof.current :xrp

      if current_user
        @btc_account = current_user.accounts.with_currency(:btc).first
        @bch_account = current_user.accounts.with_currency(:bch).first
        @dash_account = current_user.accounts.with_currency(:dash).first
        @ltc_account = current_user.accounts.with_currency(:ltc).first
        @eth_account = current_user.accounts.with_currency(:eth).first
	@xrp_account = current_user.accounts.with_currency(:xrp).first
      end
    end

    def partial_tree
      account    = current_user.accounts.with_currency(params[:id]).first
      @timestamp = Proof.with_currency(params[:id]).last.timestamp
      @json      = account.partial_tree.to_json.html_safe
      respond_to do |format|
        format.js
      end
    end

  end
end
