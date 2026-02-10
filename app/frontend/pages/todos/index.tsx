import { Form, Head, Link, router } from "@inertiajs/react"
import {
  ArrowDown,
  ArrowUp,
  Check,
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
  const [dragState, setDragState] = useState<{
    todoId: number
    sourceIndex: number
    targetIndex: number
  } | null>(null)
  const [rawDropSlot, setRawDropSlot] = useState<number | null>(null)
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
    if (!canReorder || dragState === null) {
      return filteredTodos
    }

    const reorderedTodos = [...todos]
    const [draggedTodo] = reorderedTodos.splice(dragState.sourceIndex, 1)
    if (!draggedTodo) return filteredTodos

    reorderedTodos.splice(dragState.targetIndex, 0, draggedTodo)
    return reorderedTodos
  }, [canReorder, dragState, filteredTodos, todos])

  const todoRowRefs = useRef(new Map<number, HTMLDivElement>())
  const previousRowTops = useRef(new Map<number, number>())
  const didDropRef = useRef(false)
  const isDragging = dragState !== null

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

      if (todo.id === dragState?.todoId) {
        return
      }

      element.animate(
        [
          { transform: `translateY(${delta}px)` },
          { transform: "translateY(0)" },
        ],
        { duration: 180, easing: "cubic-bezier(0.22, 1, 0.36, 1)" },
      )
    })

    previousRowTops.current = nextRowTops
  }, [renderedTodos, dragState, isDragging])

  const clearDragState = () => {
    setDragState(null)
    setRawDropSlot(null)
  }

  const selectFilter = (nextFilter: TodoFilter) => {
    clearDragState()
    setFilter(nextFilter)
  }

  const dropSlotToTargetIndex = (rawSlot: number, sourceIndex: number) => {
    const adjustedSlot = rawSlot > sourceIndex ? rawSlot - 1 : rawSlot
    return Math.max(0, Math.min(adjustedSlot, Math.max(todos.length - 1, 0)))
  }

  const updateDropSlot = (nextRawSlot: number) => {
    if (!dragState) return

    const safeRawSlot = Math.max(0, Math.min(nextRawSlot, todos.length))
    setRawDropSlot((current) => (current === safeRawSlot ? current : safeRawSlot))

    const nextTargetIndex = dropSlotToTargetIndex(
      safeRawSlot,
      dragState.sourceIndex,
    )

    setDragState((current) => {
      if (!current) return current
      if (current.targetIndex === nextTargetIndex) return current
      return {...current, targetIndex: nextTargetIndex}
    })
  }

  const submitReorder = () => {
    if (!dragState) return

    const {todoId, sourceIndex, targetIndex} = dragState
    clearDragState()

    if (sourceIndex === targetIndex) return

    router.patch(`/todos/${todoId}/reorder`, {
      position: targetIndex,
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
                onClick={() => selectFilter("all")}
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
                onClick={() => selectFilter("open")}
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
                onClick={() => selectFilter("completed")}
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
              if (!canReorder || !dragState || todos.length === 0) return

              event.preventDefault()
              event.dataTransfer.dropEffect = "move"

              const pointerY = event.clientY
              let nextRawDropSlot = todos.length

              for (const candidateTodo of renderedTodos) {
                const element = todoRowRefs.current.get(candidateTodo.id)
                if (!element) continue

                const bounds = element.getBoundingClientRect()
                const midpoint = bounds.top + bounds.height / 2

                if (pointerY < midpoint) {
                  const targetIndex = todoIndexById.get(candidateTodo.id)
                  if (targetIndex !== undefined) {
                    nextRawDropSlot = targetIndex
                  }
                  break
                }
              }

              updateDropSlot(nextRawDropSlot)
            }}
            onDrop={(event) => {
              if (!canReorder || !dragState) return

              event.preventDefault()
              didDropRef.current = true
              submitReorder()
            }}
          >
            {filteredTodos.length === 0 && (
              <p className="text-muted-foreground text-sm">{emptyStateMessage}</p>
            )}

            {renderedTodos.map((todo, index) => (
              <div key={todo.id} className="relative">
                {canReorder && dragState?.targetIndex === index && (
                  <div className="mb-2 rounded-md border border-primary/40 bg-primary/10 px-3 py-1.5 text-xs font-medium text-primary shadow-sm transition-all">
                    Insert here
                  </div>
                )}

                <div
                  ref={(element) => {
                    if (element) {
                      todoRowRefs.current.set(todo.id, element)
                    } else {
                      todoRowRefs.current.delete(todo.id)
                    }
                  }}
                  className={cn(
                    "relative flex select-none items-center justify-between rounded-lg border p-3 transition-[box-shadow,background-color,border-color,opacity] duration-150",
                    canReorder && "cursor-grab active:cursor-grabbing",
                    dragState?.todoId === todo.id &&
                      "border-primary bg-primary/10 opacity-85 shadow-xl ring-2 ring-primary/35",
                  )}
                  data-todo-row
                  data-todo-id={todo.id}
                  draggable={canReorder}
                  onDragStart={(event) => {
                    if (!canReorder) return

                    const dragOrigin = event.target as HTMLElement
                    if (dragOrigin.closest("[data-no-drag]")) {
                      event.preventDefault()
                      return
                    }

                    const sourceIndex = todoIndexById.get(todo.id)
                    if (sourceIndex === undefined) return

                    event.dataTransfer.effectAllowed = "move"
                    event.dataTransfer.setData("text/plain", String(todo.id))
                    didDropRef.current = false

                    setDragState({
                      todoId: todo.id,
                      sourceIndex,
                      targetIndex: sourceIndex,
                    })
                    setRawDropSlot(sourceIndex)
                  }}
                  onDragEnd={() => {
                    if (didDropRef.current) {
                      didDropRef.current = false
                      return
                    }

                    clearDragState()
                  }}
                >
                  <div className="flex items-center gap-2">
                  <Badge variant={todo.completed ? "default" : "outline"}>
                    {todo.completed ? "Done" : "Open"}
                  </Badge>
                  <span
                    className={todo.completed ? "text-muted-foreground line-through" : ""}
                  >
                    {todo.title}
                  </span>
                </div>

                <div className="flex items-center gap-2" data-no-drag>
                  {filter === "all" && (
                    <>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button
                            variant="outline"
                            size="icon-sm"
                            disabled={(todoIndexById.get(todo.id) ?? 0) === 0}
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
                        <TooltipContent>Move up</TooltipContent>
                      </Tooltip>

                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button
                            variant="outline"
                            size="icon-sm"
                            disabled={(todoIndexById.get(todo.id) ?? -1) === todos.length - 1}
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
                        <TooltipContent>Move down</TooltipContent>
                      </Tooltip>
                    </>
                  )}

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
              </div>
            ))}

            {canReorder && dragState && rawDropSlot === todos.length && (
              <div className="rounded-md border border-primary/40 bg-primary/10 px-3 py-1.5 text-xs font-medium text-primary shadow-sm transition-all">
                Insert at end
              </div>
            )}
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
