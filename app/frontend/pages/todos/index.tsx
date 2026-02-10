import {
  DndContext,
  type DragEndEvent,
  type DragStartEvent,
  KeyboardSensor,
  PointerSensor,
  closestCenter,
  useSensor,
  useSensors,
} from "@dnd-kit/core"
import {
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable"
import { Form, Head, Link, router } from "@inertiajs/react"
import {
  ArrowDown,
  ArrowUp,
  Check,
  GripVertical,
  RotateCcw,
  Trash2,
} from "lucide-react"
import { type CSSProperties, useLayoutEffect, useMemo, useRef, useState } from "react"

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
const focusTitleInputStorageKey = "todos.focusTitleInputAfterCreate"

interface SortableTodoRowProps {
  todo: Todo
  canReorder: boolean
  filter: TodoFilter
  index: number
  totalCount: number
  setRowElement: (id: number, element: HTMLDivElement | null) => void
  onMoveUp: () => void
  onMoveDown: () => void
  onDelete: () => void
}

function SortableTodoRow({
  todo,
  canReorder,
  filter,
  index,
  totalCount,
  setRowElement,
  onMoveUp,
  onMoveDown,
  onDelete,
}: SortableTodoRowProps) {
  const {attributes, listeners, setNodeRef, transform, transition, isDragging} =
    useSortable({
      id: todo.id,
      disabled: !canReorder,
    })

  const style: CSSProperties = {
    transition,
    transform: transform
      ? `translate3d(${transform.x}px, ${transform.y}px, 0)`
      : undefined,
  }

  return (
    <div
      ref={(element) => {
        setNodeRef(element)
        setRowElement(todo.id, element)
      }}
      style={style}
      className={cn(
        "relative flex items-center justify-between rounded-lg border p-3 transition-[box-shadow,background-color,border-color,opacity] duration-150",
        isDragging && "border-primary bg-primary/10 opacity-85 shadow-xl ring-2 ring-primary/35",
      )}
    >
      <div className="flex items-center gap-2">
        {canReorder && (
          <Tooltip>
            <TooltipTrigger asChild>
              <button
                type="button"
                aria-label={`Drag todo: ${todo.title}`}
                className="inline-flex h-7 w-7 items-center justify-center rounded-md border text-muted-foreground transition-colors hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                {...attributes}
                {...listeners}
              >
                <GripVertical className="size-4" />
              </button>
            </TooltipTrigger>
            <TooltipContent>Drag to reorder</TooltipContent>
          </Tooltip>
        )}

        <Badge variant={todo.completed ? "default" : "outline"}>
          {todo.completed ? "Done" : "Open"}
        </Badge>
        <span className={todo.completed ? "text-muted-foreground line-through" : ""}>
          {todo.title}
        </span>
      </div>

      <div className="flex items-center gap-2">
        {filter === "all" && (
          <div className="inline-flex overflow-hidden rounded-md border">
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon-sm"
                  className="rounded-none border-r"
                  disabled={index === 0}
                  aria-label="Move todo up"
                  onClick={onMoveUp}
                >
                  <ArrowUp />
                </Button>
              </TooltipTrigger>
              <TooltipContent>Move up</TooltipContent>
            </Tooltip>

            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon-sm"
                  className="rounded-none"
                  disabled={index === totalCount - 1}
                  aria-label="Move todo down"
                  onClick={onMoveDown}
                >
                  <ArrowDown />
                </Button>
              </TooltipTrigger>
              <TooltipContent>Move down</TooltipContent>
            </Tooltip>
          </div>
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
          <TooltipContent>{todo.completed ? "Reopen todo" : "Complete todo"}</TooltipContent>
        </Tooltip>

        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="destructive"
              size="icon-sm"
              aria-label="Delete todo"
              onClick={onDelete}
            >
              <Trash2 />
            </Button>
          </TooltipTrigger>
          <TooltipContent>Delete todo</TooltipContent>
        </Tooltip>
      </div>
    </div>
  )
}

export default function TodosIndex({ todos }: TodosProps) {
  const [filter, setFilter] = useState<TodoFilter>("all")
  const [todoPendingDelete, setTodoPendingDelete] = useState<Todo | null>(null)
  const [clearCompletedDialogOpen, setClearCompletedDialogOpen] = useState(false)
  const [activeTodoId, setActiveTodoId] = useState<number | null>(null)
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
  const isDragging = activeTodoId !== null
  const rowElementsById = useRef(new Map<number, HTMLDivElement>())
  const previousRowTopById = useRef(new Map<number, number>())
  const titleInputRef = useRef<HTMLInputElement>(null)

  const sortableItemIds = useMemo(
    () => filteredTodos.map((todo) => todo.id),
    [filteredTodos],
  )

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 6,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  )

  const clearDragState = () => {
    setActiveTodoId(null)
  }

  const requestTitleInputFocus = () => {
    let attempts = 0
    const maxAttempts = 12

    const tryFocus = () => {
      const input = titleInputRef.current
      if (!input || input.disabled) {
        if (attempts < maxAttempts) {
          attempts += 1
          requestAnimationFrame(tryFocus)
        }
        return
      }

      input.focus()
      input.select()
    }

    requestAnimationFrame(tryFocus)
  }

  const setRowElement = (id: number, element: HTMLDivElement | null) => {
    if (element) {
      rowElementsById.current.set(id, element)
      return
    }

    rowElementsById.current.delete(id)
  }

  const selectFilter = (nextFilter: TodoFilter) => {
    clearDragState()
    setFilter(nextFilter)
  }

  const handleDragStart = ({active}: DragStartEvent) => {
    if (!canReorder) return
    const activeId = Number(active.id)
    if (Number.isNaN(activeId)) return
    setActiveTodoId(activeId)
  }

  const handleDragEnd = ({active, over}: DragEndEvent) => {
    const activeId = Number(active.id)
    const overId = over ? Number(over.id) : NaN

    clearDragState()

    if (!canReorder || Number.isNaN(activeId) || Number.isNaN(overId)) return
    if (activeId === overId) return

    const sourceIndex = todoIndexById.get(activeId)
    const targetIndex = todoIndexById.get(overId)

    if (sourceIndex === undefined || targetIndex === undefined) return
    if (sourceIndex === targetIndex) return

    router.patch(`/todos/${activeId}/reorder`, {
      position: targetIndex,
    })
  }

  useLayoutEffect(() => {
    const nextRowTopById = new Map<number, number>()

    filteredTodos.forEach((todo) => {
      const rowElement = rowElementsById.current.get(todo.id)
      if (!rowElement) return

      nextRowTopById.set(todo.id, rowElement.getBoundingClientRect().top)
    })

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches || isDragging) {
      previousRowTopById.current = nextRowTopById
      return
    }

    filteredTodos.forEach((todo) => {
      const rowElement = rowElementsById.current.get(todo.id)
      if (!rowElement) return

      const previousTop = previousRowTopById.current.get(todo.id)
      const nextTop = nextRowTopById.get(todo.id)

      if (previousTop === undefined || nextTop === undefined) return

      const delta = previousTop - nextTop
      if (Math.abs(delta) < 1) return

      rowElement.animate(
        [
          {transform: `translateY(${delta}px)`},
          {transform: "translateY(0)"},
        ],
        {duration: 180, easing: "cubic-bezier(0.22, 1, 0.36, 1)"},
      )
    })

    previousRowTopById.current = nextRowTopById
  }, [filteredTodos, isDragging])

  useLayoutEffect(() => {
    if (typeof window === "undefined") return

    const shouldFocus =
      window.sessionStorage.getItem(focusTitleInputStorageKey) === "1"

    if (!shouldFocus) return

    window.sessionStorage.removeItem(focusTitleInputStorageKey)
    requestTitleInputFocus()
  }, [allTodosCount])

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
            onSuccess={() => {
              if (typeof window !== "undefined") {
                window.sessionStorage.setItem(focusTitleInputStorageKey, "1")
              }
              requestTitleInputFocus()
            }}
            className="mt-4 flex gap-2"
          >
            {({ errors, processing }) => (
              <>
                <div className="flex-1">
                  <Label htmlFor="title" className="sr-only">
                    Todo title
                  </Label>
                  <Input
                    ref={titleInputRef}
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

            {filter === "completed" && (
              <Button
                type="button"
                size="sm"
                variant="outline"
                disabled={completedTodosCount === 0}
                onClick={() => setClearCompletedDialogOpen(true)}
              >
                Clear completed
              </Button>
            )}
          </div>

          <DndContext
            sensors={sensors}
            collisionDetection={closestCenter}
            onDragStart={handleDragStart}
            onDragCancel={clearDragState}
            onDragEnd={handleDragEnd}
          >
            <SortableContext
              items={sortableItemIds}
              strategy={verticalListSortingStrategy}
            >
              <div className={cn("space-y-2", isDragging && "select-none")}>
                {filteredTodos.length === 0 && (
                  <p className="text-muted-foreground text-sm">{emptyStateMessage}</p>
                )}

                {filteredTodos.map((todo, index) => {
                  const todoIndex = todoIndexById.get(todo.id) ?? index

                  return (
                    <SortableTodoRow
                      key={todo.id}
                      todo={todo}
                      canReorder={canReorder}
                      filter={filter}
                      index={todoIndex}
                      totalCount={todos.length}
                      setRowElement={setRowElement}
                      onMoveUp={() => {
                        if (todoIndex <= 0) return

                        router.patch(`/todos/${todo.id}/reorder`, {
                          position: todoIndex - 1,
                        })
                      }}
                      onMoveDown={() => {
                        if (todoIndex >= todos.length - 1) return

                        router.patch(`/todos/${todo.id}/reorder`, {
                          position: todoIndex + 1,
                        })
                      }}
                      onDelete={() => setTodoPendingDelete(todo)}
                    />
                  )
                })}
              </div>
            </SortableContext>
          </DndContext>
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
