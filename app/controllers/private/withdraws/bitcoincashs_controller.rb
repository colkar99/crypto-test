module Private::Withdraws
  class BitcoincashsController < ::Private::Withdraws::BaseController
    include ::Withdraws::Withdrawable
  end
end
