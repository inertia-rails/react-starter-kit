# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Todos", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /todos" do
    context "when authenticated" do
      before { sign_in_as user }

      it "returns http success" do
        get todos_url
        expect(response).to have_http_status(:success)
      end

      it "returns only the current user's todos in inertia props" do
        own_todo = create(:todo, user: user, title: "Own todo")
        create(:todo, user: other_user, title: "Other todo")

        get todos_url

        expect(response).to have_http_status(:success)
        expect(response.body).to include(own_todo.title)
        expect(response.body).not_to include("Other todo")
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
    context "when authenticated" do
      before { sign_in_as user }

      it "creates a todo and redirects to todos" do
        expect { post todos_url, params: {title: "Buy milk"} }.to change(user.todos, :count).by(1)
        expect(response).to redirect_to(todos_url)
      end

      it "inserts a new todo at the top position" do
        first_todo = create(:todo, user: user, position: 1, title: "Existing top")
        second_todo = create(:todo, user: user, position: 2, title: "Existing second")

        post todos_url, params: {title: "New top"}

        expect(response).to redirect_to(todos_url)
        expect(user.todos.ordered.pluck(:title)).to eq(["New top", first_todo.title, second_todo.title])
        expect(user.todos.ordered.pluck(:position)).to eq([1, 2, 3])
      end

      it "does not shift positions for other users when creating a todo" do
        create(:todo, user: user, position: 1, title: "My existing")
        other_todo = create(:todo, user: other_user, position: 1, title: "Other existing")

        post todos_url, params: {title: "My new top"}

        expect(response).to redirect_to(todos_url)
        expect(user.todos.ordered.pluck(:position)).to eq([1, 2])
        expect(other_todo.reload.position).to eq(1)
      end

      it "does not create a todo with invalid params or shift existing positions" do
        first_todo = create(:todo, user: user, position: 1)
        second_todo = create(:todo, user: user, position: 2)

        expect { post todos_url, params: {title: ""} }.not_to change(user.todos, :count)
        expect(response).to redirect_to(todos_url)
        expect(first_todo.reload.position).to eq(1)
        expect(second_todo.reload.position).to eq(2)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        post todos_url, params: {title: "Buy milk"}
        expect(response).to redirect_to(sign_in_url)
      end
    end
  end

  describe "PATCH /todos/:id" do
    let(:todo) { create(:todo, user: user, completed: false) }

    context "when authenticated" do
      before { sign_in_as user }

      it "updates completion state and redirects to todos" do
        patch todo_url(todo), params: {completed: true}

        expect(response).to redirect_to(todos_url)
        expect(todo.reload.completed).to eq(true)
        expect(flash[:notice]).to eq("Todo completed")
      end

      it "reopens a completed todo and redirects to todos" do
        todo.update!(completed: true)

        patch todo_url(todo), params: {completed: false}

        expect(response).to redirect_to(todos_url)
        expect(todo.reload.completed).to eq(false)
        expect(flash[:notice]).to eq("Todo reopened")
      end

      it "returns not found for another user's todo" do
        other_todo = create(:todo, user: other_user, completed: false)

        patch todo_url(other_todo), params: {completed: true}

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        patch todo_url(todo), params: {completed: true}
        expect(response).to redirect_to(sign_in_url)
      end
    end
  end

  describe "PATCH /todos/:id/reorder" do
    context "when authenticated" do
      before { sign_in_as user }

      it "reorders todos by requested position" do
        first_todo = create(:todo, user: user, position: 1)
        second_todo = create(:todo, user: user, position: 2)
        third_todo = create(:todo, user: user, position: 3)

        patch reorder_todo_url(third_todo), params: {position: 0}

        expect(response).to redirect_to(todos_url)
        expect(user.todos.ordered.pluck(:id)).to eq([third_todo.id, first_todo.id, second_todo.id])
        expect(user.todos.ordered.pluck(:position)).to eq([1, 2, 3])
      end

      it "clamps a negative target position to the start" do
        first_todo = create(:todo, user: user, position: 1)
        second_todo = create(:todo, user: user, position: 2)

        patch reorder_todo_url(second_todo), params: {position: -8}

        expect(response).to redirect_to(todos_url)
        expect(user.todos.ordered.pluck(:id)).to eq([second_todo.id, first_todo.id])
      end

      it "clamps an oversized target position to the end" do
        first_todo = create(:todo, user: user, position: 1)
        second_todo = create(:todo, user: user, position: 2)

        patch reorder_todo_url(first_todo), params: {position: 99}

        expect(response).to redirect_to(todos_url)
        expect(user.todos.ordered.pluck(:id)).to eq([second_todo.id, first_todo.id])
      end

      it "returns not found for another user's todo" do
        other_todo = create(:todo, user: other_user)

        patch reorder_todo_url(other_todo), params: {position: 0}

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        todo = create(:todo, user: user)

        patch reorder_todo_url(todo), params: {position: 0}
        expect(response).to redirect_to(sign_in_url)
      end
    end
  end

  describe "DELETE /todos/:id" do
    let!(:todo) { create(:todo, user: user) }

    context "when authenticated" do
      before { sign_in_as user }

      it "deletes the todo and redirects to todos" do
        expect { delete todo_url(todo) }.to change { Todo.where(user_id: user.id).count }.by(-1)
        expect(response).to redirect_to(todos_url)
      end

      it "returns not found for another user's todo" do
        other_todo = create(:todo, user: other_user)

        expect { delete todo_url(other_todo) }.not_to change(Todo, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        delete todo_url(todo)
        expect(response).to redirect_to(sign_in_url)
      end
    end
  end

  describe "DELETE /todos/completed" do
    context "when authenticated" do
      before { sign_in_as user }

      it "deletes all completed todos for the current user only" do
        create(:todo, user: user, completed: true)
        create(:todo, user: user, completed: true)
        create(:todo, user: user, completed: false)
        create(:todo, user: other_user, completed: true)

        expect { delete completed_todos_url }.to change(user.todos, :count).by(-2)
        expect(response).to redirect_to(todos_url)
        expect(user.todos.where(completed: true)).to be_empty
        expect(other_user.todos.where(completed: true).count).to eq(1)
      end

      it "redirects with an alert when there are no completed todos" do
        create(:todo, user: user, completed: false)

        delete completed_todos_url

        expect(response).to redirect_to(todos_url)
        expect(flash[:alert]).to eq("No completed todos to clear")
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        delete completed_todos_url
        expect(response).to redirect_to(sign_in_url)
      end
    end
  end
end
