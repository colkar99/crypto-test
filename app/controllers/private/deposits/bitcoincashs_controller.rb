module Private
  module Deposits
    class BitcoincashsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
