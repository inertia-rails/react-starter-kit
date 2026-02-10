# frozen_string_literal: true

class TodosController < InertiaController
  before_action :set_todo, only: %i[ update destroy ]

  def index
    render inertia: {
      todos: -> { Current.user.todos.order(created_at: :desc).as_json(only: %i[id title completed created_at]) }
    }
  end

  def create
    todo = Current.user.todos.new(params.permit(:title))

    if todo.save
      redirect_to todos_path, notice: "Todo added"
    else
      redirect_to todos_path, inertia: {errors: todo.errors}
    end
  end

  def update
    if @todo.update(params.permit(:completed))
      redirect_to todos_path, notice: "Todo updated", status: :see_other
    else
      redirect_to todos_path, inertia: {errors: @todo.errors}, status: :see_other
    end
  end

  def destroy
    @todo.destroy!
    redirect_to todos_path, notice: "Todo deleted", status: :see_other
  end

  def destroy_completed
    deleted_count = Current.user.todos.where(completed: true).delete_all

    if deleted_count.positive?
      redirect_to todos_path, notice: "Completed todos cleared", status: :see_other
    else
      redirect_to todos_path, alert: "No completed todos to clear", status: :see_other
    end
  end

  private
    def set_todo
      @todo = Current.user.todos.find(params[:id])
    end
end
