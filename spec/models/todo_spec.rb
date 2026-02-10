# frozen_string_literal: true

require "rails_helper"

RSpec.describe Todo, type: :model do
  describe "validations" do
    it "requires a title" do
      todo = build(:todo, title: "")

      expect(todo).not_to be_valid
      expect(todo.errors[:title]).to include("can't be blank")
    end

    it "limits title length to 160 characters" do
      todo = build(:todo, title: "a" * 161)

      expect(todo).not_to be_valid
      expect(todo.errors[:title]).to include("is too long (maximum is 160 characters)")
    end

    it "requires position to be greater than 0" do
      todo = build(:todo, position: 0)

      expect(todo).not_to be_valid
      expect(todo.errors[:position]).to include("must be greater than 0")
    end
  end

  describe "position assignment" do
    it "assigns the next position on create when missing" do
      user = create(:user)
      create(:todo, user: user, position: 1)
      create(:todo, user: user, position: 2)

      todo = create(:todo, user: user, position: nil)

      expect(todo.position).to eq(3)
    end

    it "respects an explicit position when provided" do
      user = create(:user)

      todo = create(:todo, user: user, position: 1)

      expect(todo.position).to eq(1)
    end
  end

  describe ".ordered" do
    it "orders by position ascending" do
      user = create(:user)
      third = create(:todo, user: user, position: 3)
      first = create(:todo, user: user, position: 1)
      second = create(:todo, user: user, position: 2)

      expect(user.todos.ordered).to eq([first, second, third])
    end
  end
end
