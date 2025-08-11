export interface Task {
  id: string
  title: string
  description: string
  status: "todo" | "in-progress" | "done"
  priority: "low" | "medium" | "high" | "urgent"
  dueDate: string
  assignee: {
    name: string
    avatar: string
    email: string
  }
  tags: string[]
  progress: number
  timeEstimate: number
  timeSpent: number
}

export interface DailyGoal {
  id: string
  title: string
  target: number
  current: number
  unit: string
  icon: string
  color: string
}

export interface ProductivityMetric {
  date: string
  tasksCompleted: number
  hoursWorked: number
  focusScore: number
}

export const tasks: Task[] = [
  {
    id: "1",
    title: "Design new landing page",
    description:
      "Create wireframes and mockups for the new marketing landing page",
    status: "in-progress",
    priority: "high",
    dueDate: "2025-01-15",
    assignee: {
      name: "Sarah Chen",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah",
      email: "sarah@example.com",
    },
    tags: ["design", "ui/ux", "marketing"],
    progress: 65,
    timeEstimate: 8,
    timeSpent: 5.2,
  },
  {
    id: "2",
    title: "Fix authentication bug",
    description: "Users reporting issues with social login integration",
    status: "todo",
    priority: "urgent",
    dueDate: "2025-01-12",
    assignee: {
      name: "Alex Thompson",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
      email: "alex@example.com",
    },
    tags: ["bug", "backend", "auth"],
    progress: 0,
    timeEstimate: 4,
    timeSpent: 0,
  },
  {
    id: "3",
    title: "Write API documentation",
    description: "Document all REST endpoints for v2 API",
    status: "in-progress",
    priority: "medium",
    dueDate: "2025-01-20",
    assignee: {
      name: "Maria Garcia",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Maria",
      email: "maria@example.com",
    },
    tags: ["documentation", "api"],
    progress: 40,
    timeEstimate: 6,
    timeSpent: 2.4,
  },
  {
    id: "4",
    title: "Implement search feature",
    description: "Add full-text search with filters and sorting",
    status: "todo",
    priority: "high",
    dueDate: "2025-01-18",
    assignee: {
      name: "James Wilson",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=James",
      email: "james@example.com",
    },
    tags: ["feature", "frontend", "backend"],
    progress: 0,
    timeEstimate: 12,
    timeSpent: 0,
  },
  {
    id: "5",
    title: "Optimize database queries",
    description: "Improve performance of slow queries identified in monitoring",
    status: "done",
    priority: "medium",
    dueDate: "2025-01-10",
    assignee: {
      name: "Priya Patel",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Priya",
      email: "priya@example.com",
    },
    tags: ["performance", "database"],
    progress: 100,
    timeEstimate: 5,
    timeSpent: 4.8,
  },
  {
    id: "6",
    title: "Update user onboarding flow",
    description:
      "Simplify the registration process and add progress indicators",
    status: "in-progress",
    priority: "medium",
    dueDate: "2025-01-22",
    assignee: {
      name: "Sarah Chen",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah",
      email: "sarah@example.com",
    },
    tags: ["ux", "frontend"],
    progress: 30,
    timeEstimate: 10,
    timeSpent: 3,
  },
  {
    id: "7",
    title: "Set up CI/CD pipeline",
    description:
      "Configure automated testing and deployment with GitHub Actions",
    status: "done",
    priority: "high",
    dueDate: "2025-01-08",
    assignee: {
      name: "Alex Thompson",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
      email: "alex@example.com",
    },
    tags: ["devops", "automation"],
    progress: 100,
    timeEstimate: 8,
    timeSpent: 7.5,
  },
  {
    id: "8",
    title: "Create mobile responsive design",
    description: "Ensure all components work well on mobile devices",
    status: "todo",
    priority: "low",
    dueDate: "2025-01-25",
    assignee: {
      name: "Maria Garcia",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Maria",
      email: "maria@example.com",
    },
    tags: ["mobile", "design", "responsive"],
    progress: 0,
    timeEstimate: 15,
    timeSpent: 0,
  },
  {
    id: "9",
    title: "Add unit tests",
    description: "Increase test coverage to 80% for core modules",
    status: "in-progress",
    priority: "medium",
    dueDate: "2025-01-17",
    assignee: {
      name: "James Wilson",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=James",
      email: "james@example.com",
    },
    tags: ["testing", "quality"],
    progress: 55,
    timeEstimate: 10,
    timeSpent: 5.5,
  },
  {
    id: "10",
    title: "Migrate to TypeScript",
    description:
      "Convert JavaScript codebase to TypeScript for better type safety",
    status: "todo",
    priority: "low",
    dueDate: "2025-02-01",
    assignee: {
      name: "Priya Patel",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Priya",
      email: "priya@example.com",
    },
    tags: ["refactoring", "typescript"],
    progress: 0,
    timeEstimate: 20,
    timeSpent: 0,
  },
]

export const dailyGoals: DailyGoal[] = [
  {
    id: "1",
    title: "Tasks Completed",
    target: 8,
    current: 5,
    unit: "tasks",
    icon: "CheckCircle",
    color: "bg-gradient-to-r from-green-400 to-green-600",
  },
  {
    id: "2",
    title: "Focus Time",
    target: 6,
    current: 4.5,
    unit: "hours",
    icon: "Clock",
    color: "bg-gradient-to-r from-blue-400 to-blue-600",
  },
  {
    id: "3",
    title: "Code Reviews",
    target: 4,
    current: 3,
    unit: "reviews",
    icon: "GitPullRequest",
    color: "bg-gradient-to-r from-purple-400 to-purple-600",
  },
  {
    id: "4",
    title: "Lines of Code",
    target: 500,
    current: 367,
    unit: "lines",
    icon: "Code",
    color: "bg-gradient-to-r from-orange-400 to-orange-600",
  },
]

export const productivityMetrics: ProductivityMetric[] = [
  { date: "2025-01-01", tasksCompleted: 5, hoursWorked: 6, focusScore: 72 },
  { date: "2025-01-02", tasksCompleted: 8, hoursWorked: 7, focusScore: 85 },
  { date: "2025-01-03", tasksCompleted: 6, hoursWorked: 5, focusScore: 78 },
  { date: "2025-01-04", tasksCompleted: 10, hoursWorked: 8, focusScore: 92 },
  { date: "2025-01-05", tasksCompleted: 3, hoursWorked: 4, focusScore: 65 },
  { date: "2025-01-06", tasksCompleted: 7, hoursWorked: 6.5, focusScore: 80 },
  { date: "2025-01-07", tasksCompleted: 9, hoursWorked: 7.5, focusScore: 88 },
  { date: "2025-01-08", tasksCompleted: 4, hoursWorked: 5, focusScore: 70 },
  { date: "2025-01-09", tasksCompleted: 11, hoursWorked: 8.5, focusScore: 95 },
  { date: "2025-01-10", tasksCompleted: 6, hoursWorked: 6, focusScore: 76 },
]

export const teamMembers = [
  {
    id: "1",
    name: "Sarah Chen",
    role: "UI/UX Designer",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah",
    status: "online",
    tasksCompleted: 12,
    currentTask: "Design new landing page",
  },
  {
    id: "2",
    name: "Alex Thompson",
    role: "Full Stack Developer",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
    status: "busy",
    tasksCompleted: 18,
    currentTask: "Fix authentication bug",
  },
  {
    id: "3",
    name: "Maria Garcia",
    role: "Technical Writer",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Maria",
    status: "online",
    tasksCompleted: 8,
    currentTask: "Write API documentation",
  },
  {
    id: "4",
    name: "James Wilson",
    role: "Backend Developer",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=James",
    status: "away",
    tasksCompleted: 15,
    currentTask: "Implement search feature",
  },
  {
    id: "5",
    name: "Priya Patel",
    role: "DevOps Engineer",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Priya",
    status: "online",
    tasksCompleted: 10,
    currentTask: "Optimize database queries",
  },
]

export const recentActivities = [
  {
    id: "1",
    user: "Sarah Chen",
    action: "completed",
    target: "Homepage redesign mockup",
    time: "5 minutes ago",
    icon: "CheckCircle",
    color: "text-green-500",
  },
  {
    id: "2",
    user: "Alex Thompson",
    action: "commented on",
    target: "Authentication bug fix",
    time: "15 minutes ago",
    icon: "MessageSquare",
    color: "text-blue-500",
  },
  {
    id: "3",
    user: "Maria Garcia",
    action: "updated",
    target: "API documentation",
    time: "1 hour ago",
    icon: "Edit",
    color: "text-yellow-500",
  },
  {
    id: "4",
    user: "James Wilson",
    action: "started",
    target: "Search feature implementation",
    time: "2 hours ago",
    icon: "Play",
    color: "text-purple-500",
  },
  {
    id: "5",
    user: "Priya Patel",
    action: "deployed",
    target: "Version 2.1.0 to production",
    time: "3 hours ago",
    icon: "Rocket",
    color: "text-orange-500",
  },
]
