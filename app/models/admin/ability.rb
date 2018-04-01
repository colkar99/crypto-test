module Admin
  class Ability
    include CanCan::Ability

    def initialize(user)
      return unless user.admin?

      can :read, Order
      can :read, Trade
      can :read, Proof
      can :update, Proof
      can :manage, Document
      can :manage, Member
      can :manage, Ticket
      can :manage, IdDocument
      can :manage, TwoFactor

      can :menu, Deposit
      can :manage, ::Deposits::Bank
      can :manage, ::Deposits::Satoshi
      can :manage, ::Deposits::Litecoin
      can :manage, ::Deposits::Ether
      can :manage, ::Deposits::Dashcoin
      can :manage, ::Deposits::Bitcoincash
      can :manage, ::Deposits::Ripple

      can :menu, Withdraw
      can :manage, ::Withdraws::Bank
      can :manage, ::Withdraws::Satoshi
      can :manage, ::Withdraws::Litecoin
      can :manage, ::Withdraws::Ether
      can :manage, ::Withdraws::Bitcoincash
      can :manage, ::Withdraws::Dashcoin
      can :manage, ::Withdraws::Ripple
    end
  end
end
