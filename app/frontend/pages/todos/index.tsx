import { Form, Head, Link } from "@inertiajs/react"
import { Check, RotateCcw, Trash2 } from "lucide-react"

import InputError from "@/components/input-error"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import AppLayout from "@/layouts/app-layout"
import type { BreadcrumbItem } from "@/types"

interface Todo {
  id: number
  title: string
  completed: boolean
  created_at: string
}

interface TodosProps {
  todos: Todo[]
}

const breadcrumbs: BreadcrumbItem[] = [
  {
    title: "Todos",
    href: "/todos",
  },
]

export default function TodosIndex({ todos }: TodosProps) {
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
          <div className="mb-4 flex items-center justify-between">
            <h2 className="font-medium">Tasks</h2>
            <Badge variant="secondary">{todos.length}</Badge>
          </div>

          <div className="space-y-2">
            {todos.length === 0 && (
              <p className="text-muted-foreground text-sm">No todos yet.</p>
            )}

            {todos.map((todo) => (
              <div
                key={todo.id}
                className="flex items-center justify-between rounded-lg border p-3"
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

                <div className="flex items-center gap-2">
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
                      <Button variant="destructive" size="icon-sm" asChild>
                        <Link
                          href={`/todos/${todo.id}`}
                          method="delete"
                          as="button"
                          aria-label="Delete todo"
                          onClick={(event) => {
                            if (!window.confirm("Delete this todo?")) {
                              event.preventDefault()
                            }
                          }}
                        >
                          <Trash2 />
                        </Link>
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
    </AppLayout>
  )
}
