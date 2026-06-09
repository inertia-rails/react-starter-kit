# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  fixtures :users

  describe "email_verification" do
    let(:mail) { described_class.with(user: users(:one)).email_verification }

    it "sends to the user's email" do
      expect(mail.to).to eq([ "one@example.com" ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Verify your email")
    end
  end

  describe "password_reset" do
    let(:mail) { described_class.with(user: users(:one)).password_reset }

    it "sends to the user's email" do
      expect(mail.to).to eq([ "one@example.com" ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Reset your password")
    end
  end
end
