# frozen_string_literal: true

class TodosController < InertiaController
  before_action :set_todo, only: %i[ update destroy reorder ]

  def index
    render inertia: {
      todos: -> { Current.user.todos.ordered.as_json(only: %i[id title completed position created_at]) }
    }
  end

  def create
    todo = nil

    Todo.transaction do
      Current.user.todos.update_all("position = position + 1")
      todo = Current.user.todos.new(params.permit(:title).merge(position: 1))
      raise ActiveRecord::Rollback unless todo.save
    end

    if todo&.persisted?
      redirect_to todos_path, notice: "Todo added"
    else
      redirect_to todos_path, inertia: {errors: todo.errors}
    end
  end

  def update
    if @todo.update(params.permit(:completed))
      notice = @todo.completed? ? "Todo completed" : "Todo reopened"
      redirect_to todos_path, notice:, status: :see_other
    else
      redirect_to todos_path, inertia: {errors: @todo.errors}, status: :see_other
    end
  end

  def destroy
    @todo.destroy!
    redirect_to todos_path, notice: "Todo deleted", status: :see_other
  end

  def reorder
    todos = Current.user.todos.ordered.to_a
    ordered_ids = todos.map(&:id)
    ordered_ids.delete(@todo.id)

    target_index = params.fetch(:position, 0).to_i.clamp(0, ordered_ids.length)
    ordered_ids.insert(target_index, @todo.id)

    Todo.transaction do
      ordered_ids.each_with_index do |id, index|
        Current.user.todos.where(id: id).update_all(position: index + 1)
      end
    end

    redirect_to todos_path, status: :see_other
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
