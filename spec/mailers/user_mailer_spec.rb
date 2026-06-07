# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  fixtures :users

  describe "password_reset" do
    subject(:mail) { UserMailer.with(user:).password_reset }

    let(:user) { users(:one) }

    it "renders the headers" do
      expect(mail.subject).to eq("Reset your password")
      expect(mail.to).to eq([user.email])
    end
  end

  describe "email_verification" do
    subject(:mail) { UserMailer.with(user:).email_verification }

    let(:user) { users(:one) }

    it "renders the headers" do
      expect(mail.subject).to eq("Verify your email")
      expect(mail.to).to eq([user.email])
    end
  end
end
