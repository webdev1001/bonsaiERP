# encoding: utf-8
require 'spec_helper'

describe Payment do

  let(:movement){ Income.new_income(currency: 'BOB') {|i| i.id = 1 } }
  let(:account_to){ build :account, currency: 'USD', id: 2 }

  let(:valid_attributes) {
    {
      account_id: movement.id, account_to_id: account_to.id, exchange_rate: 7.011,
      amount: 50, total: 0, reference: 'El primer pago',
      verification: false, date: Date.today
    }
  }

  subject do
    p = Payment.new(account_id: 1, account_to_id: 2, exchange_rate: 7.001)
    p.stub(movement: movement, account_to: account_to)
    p
  end

  before(:each) do
    OrganisationSession.organisation = build :organisation, currency: 'BOB'
  end

  it "#account_to once" do
    p = Payment.new

    cash = build :cash, id: 10
    Account.should_receive(:active).once.and_return(stub(find_by_id: cash))

    p.account_to
    p.amount.should == 0
  end

  it "#amount always returns a number" do
    p = Payment.new(amount: '')
    p.amount.should  == 0

    p = Payment.new(amount: nil)
    p.amount.should  == 0

    p = Payment.new(amount: 'je')
    p.amount.should  == 0

    p = Payment.new(amount: -1)
    p.amount.should  == -1
    p.amount.should be_is_a(BigDecimal)

    p = Payment.new(amount: Object.new)
    p.amount.should  == 0
  end

  context 'Validations' do
    it { should validate_presence_of(:account_id) }
    it { should validate_presence_of(:account_to_id) }
    it { should validate_presence_of(:reference) }
    it { should validate_presence_of(:date) }

    it { should have_valid(:date).when('2012-12-12') }
    it { should_not have_valid(:date).when('anything') }
    it { should_not have_valid(:date).when('') }
    it { should_not have_valid(:date).when('2012-13-13') }

    it { should_not have_valid(:amount).when(-1) }

    it "uses the CurrencyExchange validation to validate currency accounts" do
      CurrencyExchange.any_instance.should_receive(:valid?).at_least(1).times.and_return(false)
      #CurrencyExchange.any_instance.should_receive(:valid?).and_return(false)

      p = Payment.new(valid_attributes)

      p.should_not be_valid
      p.errors_on(:base).should eq([I18n.t('errors.messages.payment.valid_accounts_currency', currency: OrganisationSession.currency)])
    end

    context "account_to" do
      before(:each) do
        Account.stub_chain(:active, :find_by_id).with(1).and_return(movement)
      end

      it "Not valid" do
        Account.stub_chain(:active, :find_by_id).with(2).and_return(nil)
        p = Payment.new(valid_attributes)
        p.stub(movement: movement)

        p.should_not be_valid
        p.errors_on(:account_to).should_not be_empty
      end

      it "Valid" do
        Account.stub_chain(:active, :find_by_id).with(account_to.id).and_return(account_to)
        p = Payment.new(valid_attributes.merge(total: 50 * 7.011))
        p.stub(movement: movement)

        p.should be_valid
      end
    end
  end

  context "Initialize" do
    subject { Payment.new(valid_attributes) }

    it "initializes verification false" do
      p = Payment.new

      p.verification.should be_false
      p.amount.should == 0
      p.exchange_rate == 1
    end

    it "initalizes verfication" do
      p = Payment.new(verification: "jajaja")
      p.verification.should be_false

      p = Payment.new(verification: "11")
      p.verification.should be_false

      p = Payment.new(verification: "01")
      p.verification.should be_false

      p = Payment.new(verification: "1")
      p.verification.should be_true

      p = Payment.new(verification: "true")
      p.verification.should_not be_false
    end
  end

  context "Invalid" do
    it "checks valid presence" do
      p = Payment.new
      p.should_not be_valid

      [:account_id, :account_to, :account_to_id].each do |met|
        p.errors[met].should_not be_blank
      end
    end

  end

end
