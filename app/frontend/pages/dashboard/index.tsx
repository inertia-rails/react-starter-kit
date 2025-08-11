import { Head } from "@inertiajs/react"
import {
  Activity,
  AlertCircle,
  Calendar,
  CheckCircle2,
  Clock,
  Code,
  Command,
  Flame,
  GitPullRequest,
  MoreHorizontal,
  Plus,
  Sparkles,
  Timer,
  TrendingUp,
  Users,
  Zap,
} from "lucide-react"
import { useEffect, useState } from "react"
import { toast } from "sonner"

import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Avatar } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  HoverCard,
  HoverCardContent,
  HoverCardTrigger,
} from "@/components/ui/hover-card"
import { Label } from "@/components/ui/label"
import { Progress } from "@/components/ui/progress"
import { Separator } from "@/components/ui/separator"
import { Slider } from "@/components/ui/slider"
import { Switch } from "@/components/ui/switch"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip"
import {
  dailyGoals,
  recentActivities,
  tasks,
  teamMembers,
} from "@/data/dashboard-mock-data"
import AppLayout from "@/layouts/app-layout"
import { dashboardPath } from "@/routes"
import type { BreadcrumbItem } from "@/types"

import EnhancedDashboardSection from "./productivity-enhanced"

const breadcrumbs: BreadcrumbItem[] = [
  {
    title: "Productivity Dashboard",
    href: dashboardPath(),
  },
]

export default function Dashboard() {
  const [taskFilter, setTaskFilter] = useState("all")
  const [, setShowCommandPalette] = useState(false)
  const [pomodoroTime, setPomodoroTime] = useState(25)
  const [isTimerRunning, setIsTimerRunning] = useState(false)
  const [currentTime, setCurrentTime] = useState(pomodoroTime * 60)
  const [autoArchive, setAutoArchive] = useState(true)
  const [emailNotifications, setEmailNotifications] = useState(false)

  // Filter tasks based on selected tab
  const filteredTasks =
    taskFilter === "all"
      ? tasks
      : tasks.filter((task) => task.status === taskFilter)

  // Calculate stats
  const totalTasks = tasks.length
  const completedTasks = tasks.filter((t) => t.status === "done").length
  const urgentTasks = tasks.filter((t) => t.priority === "urgent").length
  const inProgressTasks = tasks.filter((t) => t.status === "in-progress").length

  // Timer effect
  useEffect(() => {
    let interval: ReturnType<typeof setInterval>
    if (isTimerRunning && currentTime > 0) {
      interval = setInterval(() => {
        setCurrentTime((time) => time - 1)
      }, 1000)
    } else if (currentTime === 0) {
      setIsTimerRunning(false)
      toast.success("Pomodoro session completed! Time for a break 🎉")
    }
    return () => clearInterval(interval)
  }, [isTimerRunning, currentTime])

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "urgent":
        return "bg-red-500 text-white"
      case "high":
        return "bg-orange-500 text-white"
      case "medium":
        return "bg-yellow-500 text-white"
      case "low":
        return "bg-green-500 text-white"
      default:
        return "bg-gray-500 text-white"
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "done":
        return <CheckCircle2 className="h-4 w-4 text-green-500" />
      case "in-progress":
        return <Clock className="h-4 w-4 text-blue-500" />
      default:
        return <AlertCircle className="h-4 w-4 text-gray-500" />
    }
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />
      <TooltipProvider>
        <div className="flex h-full flex-1 flex-col gap-6 overflow-x-auto p-4">
          {/* Welcome Alert */}
          <Alert className="border-purple-200 bg-gradient-to-r from-purple-50 to-pink-50 dark:border-purple-800 dark:from-purple-950 dark:to-pink-950">
            <Sparkles className="h-4 w-4" />
            <AlertTitle>Welcome back! You&apos;re on fire today 🔥</AlertTitle>
            <AlertDescription>
              You&apos;ve completed {completedTasks} tasks and have{" "}
              {urgentTasks} urgent items pending. Keep up the great work!
            </AlertDescription>
          </Alert>

          {/* Stats Overview */}
          <div className="grid gap-4 md:grid-cols-4">
            {dailyGoals.map((goal) => {
              const IconComponent =
                goal.icon === "CheckCircle"
                  ? CheckCircle2
                  : goal.icon === "Clock"
                    ? Clock
                    : goal.icon === "GitPullRequest"
                      ? GitPullRequest
                      : Code
              const percentage = (goal.current / goal.target) * 100

              return (
                <Card key={goal.id} className="overflow-hidden">
                  <div className={`h-2 ${goal.color}`} />
                  <CardHeader className="pb-2">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-sm font-medium">
                        {goal.title}
                      </CardTitle>
                      <IconComponent className="text-muted-foreground h-4 w-4" />
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {goal.current}/{goal.target} {goal.unit}
                    </div>
                    <Progress value={percentage} className="mt-2" />
                    <p className="text-muted-foreground mt-2 text-xs">
                      {percentage.toFixed(0)}% of daily goal
                    </p>
                  </CardContent>
                </Card>
              )
            })}
          </div>

          {/* Main Content Grid */}
          <div className="grid gap-6 lg:grid-cols-7">
            {/* Task Management Section */}
            <div className="lg:col-span-4">
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>Task Management</CardTitle>
                      <CardDescription>
                        Track and manage your daily tasks
                      </CardDescription>
                    </div>
                    <div className="flex gap-2">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button
                            size="sm"
                            className="bg-gradient-to-r from-purple-500 to-pink-500 text-white"
                          >
                            <Plus className="mr-1 h-4 w-4" /> New Task
                          </Button>
                        </DialogTrigger>
                        <DialogContent>
                          <DialogHeader>
                            <DialogTitle>Create New Task</DialogTitle>
                            <DialogDescription>
                              Add a new task to your productivity dashboard
                            </DialogDescription>
                          </DialogHeader>
                          <div className="grid gap-4 py-4">
                            <div className="grid gap-2">
                              <Label>Task Title</Label>
                              <input
                                className="flex h-9 w-full rounded-md border bg-transparent px-3 py-1 text-sm"
                                placeholder="Enter task title"
                              />
                            </div>
                            <div className="grid gap-2">
                              <Label>Priority</Label>
                              <Slider defaultValue={[2]} max={4} step={1} />
                            </div>
                            <div className="flex items-center space-x-2">
                              <Switch id="urgent" />
                              <Label htmlFor="urgent">Mark as urgent</Label>
                            </div>
                          </div>
                          <Button
                            onClick={() =>
                              toast.success("Task created successfully!")
                            }
                          >
                            Create Task
                          </Button>
                        </DialogContent>
                      </Dialog>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setShowCommandPalette(true)}
                      >
                        <Command className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <Tabs value={taskFilter} onValueChange={setTaskFilter}>
                    <TabsList className="grid w-full grid-cols-4">
                      <TabsTrigger value="all">All ({totalTasks})</TabsTrigger>
                      <TabsTrigger value="todo">
                        To Do ({tasks.filter((t) => t.status === "todo").length}
                        )
                      </TabsTrigger>
                      <TabsTrigger value="in-progress">
                        In Progress ({inProgressTasks})
                      </TabsTrigger>
                      <TabsTrigger value="done">
                        Done ({completedTasks})
                      </TabsTrigger>
                    </TabsList>
                    <TabsContent value={taskFilter} className="mt-4 space-y-4">
                      {filteredTasks.map((task) => (
                        <div
                          key={task.id}
                          className="rounded-lg border p-4 transition-shadow hover:shadow-md"
                        >
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <div className="mb-2 flex items-center gap-2">
                                {getStatusIcon(task.status)}
                                <h4 className="font-semibold">{task.title}</h4>
                                <Badge
                                  className={getPriorityColor(task.priority)}
                                >
                                  {task.priority}
                                </Badge>
                              </div>
                              <p className="text-muted-foreground mb-3 text-sm">
                                {task.description}
                              </p>
                              <div className="flex items-center gap-4 text-sm">
                                <HoverCard>
                                  <HoverCardTrigger asChild>
                                    <div className="flex cursor-pointer items-center gap-2">
                                      <Avatar className="h-6 w-6">
                                        <img
                                          src={task.assignee.avatar}
                                          alt={task.assignee.name}
                                        />
                                      </Avatar>
                                      <span>{task.assignee.name}</span>
                                    </div>
                                  </HoverCardTrigger>
                                  <HoverCardContent className="w-80">
                                    <div className="flex justify-between space-x-4">
                                      <Avatar>
                                        <img
                                          src={task.assignee.avatar}
                                          alt={task.assignee.name}
                                        />
                                      </Avatar>
                                      <div className="space-y-1">
                                        <h4 className="text-sm font-semibold">
                                          {task.assignee.name}
                                        </h4>
                                        <p className="text-sm">
                                          {task.assignee.email}
                                        </p>
                                        <div className="flex items-center pt-2">
                                          <Calendar className="mr-2 h-4 w-4 opacity-70" />
                                          <span className="text-muted-foreground text-xs">
                                            Due: {task.dueDate}
                                          </span>
                                        </div>
                                      </div>
                                    </div>
                                  </HoverCardContent>
                                </HoverCard>
                                <div className="flex items-center gap-1">
                                  <Clock className="h-4 w-4" />
                                  <span>
                                    {task.timeSpent}/{task.timeEstimate}h
                                  </span>
                                </div>
                                <div className="flex gap-1">
                                  {task.tags.map((tag) => (
                                    <Badge
                                      key={tag}
                                      variant="secondary"
                                      className="text-xs"
                                    >
                                      {tag}
                                    </Badge>
                                  ))}
                                </div>
                              </div>
                              <Progress
                                value={task.progress}
                                className="mt-3"
                              />
                            </div>
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="sm">
                                  <MoreHorizontal className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuItem
                                  onClick={() =>
                                    toast.info("Editing task: " + task.title)
                                  }
                                >
                                  Edit
                                </DropdownMenuItem>
                                <DropdownMenuItem
                                  onClick={() =>
                                    toast.success("Task marked as complete!")
                                  }
                                >
                                  Mark Complete
                                </DropdownMenuItem>
                                <DropdownMenuItem
                                  className="text-red-600"
                                  onClick={() => toast.error("Task deleted")}
                                >
                                  Delete
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </div>
                        </div>
                      ))}
                    </TabsContent>
                  </Tabs>
                </CardContent>
              </Card>
            </div>

            {/* Right Sidebar */}
            <div className="space-y-6 lg:col-span-3">
              {/* Pomodoro Timer */}
              <Card className="bg-gradient-to-br from-orange-50 to-red-50 dark:from-orange-950 dark:to-red-950">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Timer className="h-5 w-5" />
                    Pomodoro Timer
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-center">
                    <div className="mb-4 text-5xl font-bold">
                      {formatTime(currentTime)}
                    </div>
                    <div className="mb-4 flex justify-center gap-2">
                      <Button
                        onClick={() => {
                          setIsTimerRunning(!isTimerRunning)
                          if (!isTimerRunning) {
                            toast.success("Timer started! Stay focused 💪")
                          }
                        }}
                        className="bg-gradient-to-r from-orange-500 to-red-500 text-white"
                      >
                        {isTimerRunning ? "Pause" : "Start"}
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => {
                          setCurrentTime(pomodoroTime * 60)
                          setIsTimerRunning(false)
                        }}
                      >
                        Reset
                      </Button>
                    </div>
                    <div className="space-y-2">
                      <Label>Session Length: {pomodoroTime} minutes</Label>
                      <Slider
                        value={[pomodoroTime]}
                        onValueChange={(value) => {
                          setPomodoroTime(value[0])
                          setCurrentTime(value[0] * 60)
                        }}
                        max={60}
                        min={5}
                        step={5}
                      />
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Team Activity */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Users className="h-5 w-5" />
                    Team Activity
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <Accordion type="single" collapsible className="w-full">
                    {teamMembers.map((member) => (
                      <AccordionItem key={member.id} value={member.id}>
                        <AccordionTrigger>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-8 w-8">
                              <img src={member.avatar} alt={member.name} />
                            </Avatar>
                            <div className="text-left">
                              <p className="text-sm font-medium">
                                {member.name}
                              </p>
                              <p className="text-muted-foreground text-xs">
                                {member.role}
                              </p>
                            </div>
                          </div>
                        </AccordionTrigger>
                        <AccordionContent>
                          <div className="space-y-2 pt-2">
                            <div className="flex justify-between text-sm">
                              <span>Status:</span>
                              <Badge
                                variant={
                                  member.status === "online"
                                    ? "default"
                                    : "secondary"
                                }
                              >
                                {member.status}
                              </Badge>
                            </div>
                            <div className="flex justify-between text-sm">
                              <span>Tasks Completed:</span>
                              <span className="font-semibold">
                                {member.tasksCompleted}
                              </span>
                            </div>
                            <div className="text-sm">
                              <span>Current Task:</span>
                              <p className="text-muted-foreground">
                                {member.currentTask}
                              </p>
                            </div>
                          </div>
                        </AccordionContent>
                      </AccordionItem>
                    ))}
                  </Accordion>
                </CardContent>
              </Card>

              {/* Recent Activity Feed */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Activity className="h-5 w-5" />
                    Recent Activity
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {recentActivities.map((activity) => (
                      <div key={activity.id} className="flex items-start gap-3">
                        <div className={`mt-1 ${activity.color}`}>
                          <Zap className="h-4 w-4" />
                        </div>
                        <div className="flex-1 space-y-1">
                          <p className="text-sm">
                            <span className="font-medium">{activity.user}</span>{" "}
                            {activity.action}{" "}
                            <span className="font-medium">
                              {activity.target}
                            </span>
                          </p>
                          <p className="text-muted-foreground text-xs">
                            {activity.time}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              {/* Settings */}
              <Card>
                <CardHeader>
                  <CardTitle>Quick Settings</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center justify-between">
                    <Label
                      htmlFor="auto-archive"
                      className="flex items-center gap-2"
                    >
                      Auto-archive completed tasks
                    </Label>
                    <Switch
                      id="auto-archive"
                      checked={autoArchive}
                      onCheckedChange={setAutoArchive}
                    />
                  </div>
                  <Separator />
                  <div className="flex items-center justify-between">
                    <Label
                      htmlFor="email-notif"
                      className="flex items-center gap-2"
                    >
                      Email notifications
                    </Label>
                    <Switch
                      id="email-notif"
                      checked={emailNotifications}
                      onCheckedChange={setEmailNotifications}
                    />
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Productivity Trends */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Productivity Trends</CardTitle>
                  <CardDescription>
                    Your performance over the last 10 days
                  </CardDescription>
                </div>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button variant="outline" size="sm">
                      <TrendingUp className="h-4 w-4" />
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent>
                    <p>View detailed analytics</p>
                  </TooltipContent>
                </Tooltip>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-3">
                <div className="space-y-2">
                  <p className="text-sm font-medium">Average Tasks/Day</p>
                  <p className="text-2xl font-bold text-green-600">6.7</p>
                  <p className="text-muted-foreground text-xs">
                    ↑ 12% from last week
                  </p>
                </div>
                <div className="space-y-2">
                  <p className="text-sm font-medium">Focus Score</p>
                  <p className="text-2xl font-bold text-blue-600">79.3</p>
                  <p className="text-muted-foreground text-xs">
                    ↑ 5% from last week
                  </p>
                </div>
                <div className="space-y-2">
                  <p className="text-sm font-medium">Streak</p>
                  <div className="flex items-center gap-2">
                    <p className="text-2xl font-bold text-orange-600">7 days</p>
                    <Flame className="h-6 w-6 text-orange-500" />
                  </div>
                  <p className="text-muted-foreground text-xs">Keep it up!</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Enhanced Dashboard Section with New Components */}
        <div className="mt-8">
          <h2 className="text-2xl font-bold mb-4 bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
            Enhanced Productivity Features
          </h2>
          <EnhancedDashboardSection />
        </div>
      </TooltipProvider>
    </AppLayout>
  )
}
