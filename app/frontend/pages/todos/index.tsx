import { Form, Head, Link, router } from "@inertiajs/react"
import {
  ArrowDown,
  ArrowUp,
  Check,
  GripVertical,
  RotateCcw,
  Trash2,
} from "lucide-react"
import { useLayoutEffect, useMemo, useRef, useState } from "react"

import InputError from "@/components/input-error"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogTitle,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import AppLayout from "@/layouts/app-layout"
import { cn } from "@/lib/utils"
import type { BreadcrumbItem } from "@/types"

interface Todo {
  id: number
  title: string
  completed: boolean
  position: number
  created_at: string
}

interface TodosProps {
  todos: Todo[]
}

type TodoFilter = "all" | "open" | "completed"

const breadcrumbs: BreadcrumbItem[] = [
  {
    title: "Todos",
    href: "/todos",
  },
]

export default function TodosIndex({ todos }: TodosProps) {
  const [filter, setFilter] = useState<TodoFilter>("all")
  const [todoPendingDelete, setTodoPendingDelete] = useState<Todo | null>(null)
  const [clearCompletedDialogOpen, setClearCompletedDialogOpen] = useState(false)
  const [draggedTodoId, setDraggedTodoId] = useState<number | null>(null)
  const [dropIndex, setDropIndex] = useState<number | null>(null)
  const [dropMarker, setDropMarker] = useState<{
    todoId: number
    edge: "before" | "after"
  } | null>(null)
  const allTodosCount = todos.length
  const openTodosCount = todos.filter((todo) => !todo.completed).length
  const completedTodosCount = todos.filter((todo) => todo.completed).length
  const canReorder = filter === "all"

  const filteredTodos = useMemo(() => {
    if (filter === "open") return todos.filter((todo) => !todo.completed)
    if (filter === "completed") return todos.filter((todo) => todo.completed)
    return todos
  }, [todos, filter])

  const emptyStateMessage = useMemo(() => {
    if (filter === "open") return "No open todos yet."
    if (filter === "completed") return "No completed todos yet."
    return "No todos yet."
  }, [filter])

  const todoIndexById = useMemo(
    () => new Map(todos.map((todo, index) => [todo.id, index])),
    [todos],
  )

  const renderedTodos = useMemo(() => {
    if (!canReorder || draggedTodoId === null || dropIndex === null) {
      return filteredTodos
    }

    const draggedTodo = todos.find((todo) => todo.id === draggedTodoId)
    if (!draggedTodo) return filteredTodos

    const remainingTodos = todos.filter((todo) => todo.id !== draggedTodoId)
    const safeIndex = Math.max(0, Math.min(dropIndex, remainingTodos.length))

    return [
      ...remainingTodos.slice(0, safeIndex),
      draggedTodo,
      ...remainingTodos.slice(safeIndex),
    ]
  }, [canReorder, draggedTodoId, dropIndex, filteredTodos, todos])

  const todoRowRefs = useRef(new Map<number, HTMLDivElement>())
  const previousRowTops = useRef(new Map<number, number>())

  useLayoutEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      previousRowTops.current = new Map(
        renderedTodos.flatMap((todo) => {
          const element = todoRowRefs.current.get(todo.id)
          if (!element) return []
          return [[todo.id, element.getBoundingClientRect().top] as const]
        }),
      )
      return
    }

    const nextRowTops = new Map<number, number>()

    renderedTodos.forEach((todo) => {
      const element = todoRowRefs.current.get(todo.id)
      if (!element) return

      const top = element.getBoundingClientRect().top
      nextRowTops.set(todo.id, top)

      const previousTop = previousRowTops.current.get(todo.id)
      if (previousTop === undefined) return

      const delta = previousTop - top
      if (Math.abs(delta) < 1) return

      element.animate(
        [
          { transform: `translateY(${delta}px)` },
          { transform: "translateY(0)" },
        ],
        { duration: 220, easing: "cubic-bezier(0.2, 0, 0, 1)" },
      )
    })

    previousRowTops.current = nextRowTops
  }, [renderedTodos])

  const resolveDropIndex = (sourceIndex: number, rawDropIndex: number) => {
    const adjustedDropIndex =
      rawDropIndex > sourceIndex ? rawDropIndex - 1 : rawDropIndex
    return Math.max(0, Math.min(adjustedDropIndex, todos.length - 1))
  }

  const submitReorder = (sourceId: number, position: number) => {
    setDraggedTodoId(null)
    setDropIndex(null)
    setDropMarker(null)

    router.patch(`/todos/${sourceId}/reorder`, {
      position,
    })
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <div className="mx-auto flex w-full max-w-3xl flex-col gap-6 p-4">
        <section className="rounded-xl border p-4">
          <h1 className="text-xl font-semibold">Todo list</h1>
          <p className="text-muted-foreground mt-1 text-sm">
            Add tasks, mark them complete, and remove them when done.
          </p>

          <Form
            action="/todos"
            method="post"
            resetOnSuccess={["title"]}
            className="mt-4 flex gap-2"
          >
            {({ errors, processing }) => (
              <>
                <div className="flex-1">
                  <Label htmlFor="title" className="sr-only">
                    Todo title
                  </Label>
                  <Input
                    id="title"
                    name="title"
                    placeholder="What needs to be done?"
                    autoComplete="off"
                    disabled={processing}
                  />
                  <InputError messages={errors.title} className="mt-2" />
                </div>
                <Button type="submit" disabled={processing}>
                  Add
                </Button>
              </>
            )}
          </Form>
        </section>

        <section className="rounded-xl border p-4">
          <div className="mb-4">
            <h2 className="font-medium">Tasks</h2>
          </div>

          <div className="mb-4 flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <Button
                type="button"
                size="sm"
                variant={filter === "all" ? "default" : "outline"}
                onClick={() => setFilter("all")}
              >
                <span>All</span>
                <span className="rounded-full bg-black/10 px-2 py-0.5 text-xs dark:bg-white/15">
                  {allTodosCount}
                </span>
              </Button>
              <Button
                type="button"
                size="sm"
                variant={filter === "open" ? "default" : "outline"}
                onClick={() => setFilter("open")}
              >
                <span>Open</span>
                <span className="rounded-full bg-black/10 px-2 py-0.5 text-xs dark:bg-white/15">
                  {openTodosCount}
                </span>
              </Button>
              <Button
                type="button"
                size="sm"
                variant={filter === "completed" ? "default" : "outline"}
                onClick={() => setFilter("completed")}
              >
                <span>Complete</span>
                <span className="rounded-full bg-black/10 px-2 py-0.5 text-xs dark:bg-white/15">
                  {completedTodosCount}
                </span>
              </Button>
            </div>

            <Button
              type="button"
              size="sm"
              variant="outline"
              disabled={completedTodosCount === 0}
              onClick={() => setClearCompletedDialogOpen(true)}
            >
              Clear completed
            </Button>
          </div>

          <div
            className="space-y-2"
            onDragOver={(event) => {
              if (!canReorder || draggedTodoId === null || todos.length === 0) return

              event.preventDefault()
              event.dataTransfer.dropEffect = "move"
              const sourceIndex = todoIndexById.get(draggedTodoId)
              if (sourceIndex === undefined) return

              const container = event.currentTarget
              const firstRow = container.querySelector("[data-todo-row]")
              const lastRow = container.querySelector("[data-todo-row]:last-of-type")

              if (!(firstRow instanceof HTMLElement) || !(lastRow instanceof HTMLElement)) {
                return
              }

              const pointerY = event.clientY
              const firstTop = firstRow.getBoundingClientRect().top
              const lastBottom = lastRow.getBoundingClientRect().bottom

              if (pointerY <= firstTop) {
                setDropIndex(resolveDropIndex(sourceIndex, 0))
              } else if (pointerY >= lastBottom) {
                setDropIndex(resolveDropIndex(sourceIndex, todos.length))
              }
            }}
            onDrop={(event) => {
              if (!canReorder || draggedTodoId === null || dropIndex === null) return

              event.preventDefault()
              const sourceIndex = todoIndexById.get(draggedTodoId)
              if (sourceIndex === undefined || sourceIndex === dropIndex) {
                setDraggedTodoId(null)
                setDropIndex(null)
                setDropMarker(null)
                return
              }

              submitReorder(draggedTodoId, dropIndex)
            }}
          >
            {filteredTodos.length === 0 && (
              <p className="text-muted-foreground text-sm">{emptyStateMessage}</p>
            )}

            {renderedTodos.map((todo) => (
              <div
                key={todo.id}
                ref={(element) => {
                  if (element) {
                    todoRowRefs.current.set(todo.id, element)
                  } else {
                    todoRowRefs.current.delete(todo.id)
                  }
                }}
                className={cn(
                  "relative flex items-center justify-between rounded-lg border p-3 transition-colors",
                  todo.id === draggedTodoId &&
                    "border-primary/80 bg-primary/10 shadow-md ring-1 ring-primary/30",
                )}
                data-todo-row
                onDragOver={(event) => {
                  if (!canReorder || draggedTodoId === null) return

                  event.preventDefault()
                  event.dataTransfer.dropEffect = "move"

                  const sourceIndex = todoIndexById.get(draggedTodoId)
                  const targetIndex = todoIndexById.get(todo.id)
                  if (sourceIndex === undefined || targetIndex === undefined) return

                  const bounds = event.currentTarget.getBoundingClientRect()
                  const dropBeforeTarget = event.clientY < bounds.top + bounds.height / 2
                  setDropMarker({
                    todoId: todo.id,
                    edge: dropBeforeTarget ? "before" : "after",
                  })
                  const rawDropIndex = dropBeforeTarget ? targetIndex : targetIndex + 1

                  setDropIndex(resolveDropIndex(sourceIndex, rawDropIndex))
                }}
                onDragLeave={(event) => {
                  if (event.currentTarget.contains(event.relatedTarget as Node | null)) {
                    return
                  }
                }}
                onDrop={(event) => {
                  if (!canReorder || draggedTodoId === null || dropIndex === null) return

                  event.preventDefault()
                  const sourceIndex = todoIndexById.get(draggedTodoId)
                  if (sourceIndex === undefined || sourceIndex === dropIndex) {
                    setDraggedTodoId(null)
                    setDropIndex(null)
                    setDropMarker(null)
                    return
                  }

                  submitReorder(draggedTodoId, dropIndex)
                }}
              >
                {canReorder &&
                  draggedTodoId !== null &&
                  dropMarker?.todoId === todo.id &&
                  dropMarker.edge === "before" && (
                    <div className="absolute -top-1 left-3 right-3 h-0.5 rounded-full bg-primary" />
                  )}
                {canReorder &&
                  draggedTodoId !== null &&
                  dropMarker?.todoId === todo.id &&
                  dropMarker.edge === "after" && (
                    <div className="absolute -bottom-1 left-3 right-3 h-0.5 rounded-full bg-primary" />
                  )}
                <div className="flex items-center gap-2">
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button
                        type="button"
                        variant="outline"
                        size="icon-sm"
                        aria-label="Drag to reorder todo"
                        draggable={canReorder}
                        disabled={!canReorder}
                        onDragStart={(event) => {
                          setDraggedTodoId(todo.id)
                          const sourceIndex = todoIndexById.get(todo.id)
                          setDropIndex(sourceIndex ?? null)
                          event.dataTransfer.effectAllowed = "move"
                          event.dataTransfer.setData("text/plain", String(todo.id))
                        }}
                        onDragEnd={() => {
                          setDraggedTodoId(null)
                          setDropIndex(null)
                          setDropMarker(null)
                        }}
                      >
                        <GripVertical />
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>
                      {canReorder
                        ? "Drag to reorder"
                        : "Switch to All filter to reorder"}
                    </TooltipContent>
                  </Tooltip>

                  <Badge variant={todo.completed ? "default" : "outline"}>
                    {todo.completed ? "Done" : "Open"}
                  </Badge>
                  <span
                    className={todo.completed ? "text-muted-foreground line-through" : ""}
                  >
                    {todo.title}
                  </span>
                </div>

                <div className="flex items-center gap-2">
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button
                        variant="outline"
                        size="icon-sm"
                        disabled={
                          filter !== "all" || (todoIndexById.get(todo.id) ?? 0) === 0
                        }
                        aria-label="Move todo up"
                        onClick={() => {
                          const currentIndex = todoIndexById.get(todo.id)
                          if (currentIndex === undefined || currentIndex <= 0) return

                          router.patch(`/todos/${todo.id}/reorder`, {
                            position: currentIndex - 1,
                          })
                        }}
                      >
                        <ArrowUp />
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>
                      {filter === "all"
                        ? "Move up"
                        : "Switch to All filter to reorder"}
                    </TooltipContent>
                  </Tooltip>

                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button
                        variant="outline"
                        size="icon-sm"
                        disabled={
                          filter !== "all" ||
                          (todoIndexById.get(todo.id) ?? -1) === todos.length - 1
                        }
                        aria-label="Move todo down"
                        onClick={() => {
                          const currentIndex = todoIndexById.get(todo.id)
                          if (
                            currentIndex === undefined ||
                            currentIndex >= todos.length - 1
                          ) {
                            return
                          }

                          router.patch(`/todos/${todo.id}/reorder`, {
                            position: currentIndex + 1,
                          })
                        }}
                      >
                        <ArrowDown />
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>
                      {filter === "all"
                        ? "Move down"
                        : "Switch to All filter to reorder"}
                    </TooltipContent>
                  </Tooltip>

                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button variant="outline" size="icon-sm" asChild>
                        <Link
                          href={`/todos/${todo.id}`}
                          method="patch"
                          as="button"
                          data={{completed: !todo.completed}}
                          aria-label={todo.completed ? "Reopen todo" : "Complete todo"}
                        >
                          {todo.completed ? <RotateCcw /> : <Check />}
                        </Link>
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>
                      {todo.completed ? "Reopen todo" : "Complete todo"}
                    </TooltipContent>
                  </Tooltip>

                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button
                        variant="destructive"
                        size="icon-sm"
                        aria-label="Delete todo"
                        onClick={() => setTodoPendingDelete(todo)}
                      >
                        <Trash2 />
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>Delete todo</TooltipContent>
                  </Tooltip>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      <Dialog
        open={todoPendingDelete !== null}
        onOpenChange={(open) => {
          if (!open) setTodoPendingDelete(null)
        }}
      >
        <DialogContent>
          <DialogTitle>Delete todo?</DialogTitle>
          <DialogDescription>
            This will permanently remove{" "}
            <span className="font-medium">{todoPendingDelete?.title}</span>.
          </DialogDescription>
          <DialogFooter>
            <DialogClose asChild>
              <Button variant="secondary">Cancel</Button>
            </DialogClose>
            <Button
              variant="destructive"
              onClick={() => {
                if (!todoPendingDelete) return
                router.delete(`/todos/${todoPendingDelete.id}`, {
                  onSuccess: () => setTodoPendingDelete(null),
                })
              }}
            >
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog
        open={clearCompletedDialogOpen}
        onOpenChange={setClearCompletedDialogOpen}
      >
        <DialogContent>
          <DialogTitle>Clear all completed todos?</DialogTitle>
          <DialogDescription>
            This will remove all completed tasks from your list.
          </DialogDescription>
          <DialogFooter>
            <DialogClose asChild>
              <Button variant="secondary">Cancel</Button>
            </DialogClose>
            <Button
              variant="destructive"
              onClick={() => {
                router.delete("/todos/completed", {
                  onSuccess: () => setClearCompletedDialogOpen(false),
                })
              }}
            >
              Clear completed
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AppLayout>
  )
}
