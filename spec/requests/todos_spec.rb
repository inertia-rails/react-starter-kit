# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Todos", type: :request do
  let(:user) { create(:user) }

  describe "GET /todos" do
    context "when authenticated" do
      before { sign_in_as user }

      it "returns http success" do
        get todos_url
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        get todos_url
        expect(response).to redirect_to(sign_in_url)
      end
    end
  end

  describe "POST /todos" do
    before { sign_in_as user }

    it "creates a todo and redirects to todos" do
      expect { post todos_url, params: {title: "Buy milk"} }.to change(user.todos, :count).by(1)
      expect(response).to redirect_to(todos_url)
    end

    it "does not create a todo with invalid params" do
      expect { post todos_url, params: {title: ""} }.not_to change(user.todos, :count)
      expect(response).to redirect_to(todos_url)
    end
  end

  describe "PATCH /todos/:id" do
    before { sign_in_as user }

    it "updates completion state and redirects to todos" do
      todo = create(:todo, user: user, completed: false)

      patch todo_url(todo), params: {completed: true}

      expect(response).to redirect_to(todos_url)
      expect(todo.reload.completed).to eq(true)
    end
  end

  describe "DELETE /todos/:id" do
    before { sign_in_as user }

    it "deletes the todo and redirects to todos" do
      todo = create(:todo, user: user)

      expect { delete todo_url(todo) }.to change(user.todos, :count).by(-1)
      expect(response).to redirect_to(todos_url)
    end
  end

  describe "DELETE /todos/completed" do
    before { sign_in_as user }

    it "deletes all completed todos" do
      create(:todo, user: user, completed: true)
      create(:todo, user: user, completed: true)
      create(:todo, user: user, completed: false)

      expect { delete completed_todos_url }.to change(user.todos, :count).by(-2)
      expect(response).to redirect_to(todos_url)
      expect(user.todos.where(completed: true)).to be_empty
    end
  end
end
