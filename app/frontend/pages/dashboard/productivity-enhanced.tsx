import { Head, Link } from "@inertiajs/react"
import { format, isSameDay } from "date-fns"
import {
  Calendar as CalendarIcon,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  Circle,
  Command as CommandIcon,
  Copy,
  Edit,
  Heart,
  Home,
  Info,
  Plus,
  Search,
  Settings,
  Sparkles,
  Target,
  Trash,
  Trophy,
  User
} from "lucide-react"
import { useEffect, useState } from "react"

// All UI Components
import { toast } from "sonner"

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from "@/components/ui/carousel"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
  CommandShortcut,
} from "@/components/ui/command"
import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuRadioGroup,
  ContextMenuSeparator,
  ContextMenuShortcut,
  ContextMenuRadioItem,
  ContextMenuSub,
  ContextMenuSubContent,
  ContextMenuSubTrigger,
  ContextMenuTrigger
} from "@/components/ui/context-menu"
import {
  HoverCard,
  HoverCardContent,
  HoverCardTrigger,
} from "@/components/ui/hover-card"
import { Label } from "@/components/ui/label"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip"

// Mock data
import { tasks } from "@/data/dashboard-mock-data"
import { rootPath } from "@/routes"

const achievements = [
  { id: 1, title: "Early Bird", description: "Complete 5 tasks before 9 AM", icon: "🌅", color: "bg-gradient-to-r from-yellow-400 to-orange-500", progress: 3, total: 5 },
  { id: 2, title: "Sprint Master", description: "Complete 10 tasks in one day", icon: "🏃", color: "bg-gradient-to-r from-blue-400 to-purple-500", progress: 7, total: 10 },
  { id: 3, title: "Focus Ninja", description: "3 hour focus streak", icon: "🥷", color: "bg-gradient-to-r from-green-400 to-teal-500", progress: 2, total: 3 },
  { id: 4, title: "Team Player", description: "Help 5 teammates", icon: "🤝", color: "bg-gradient-to-r from-pink-400 to-red-500", progress: 5, total: 5 },
  { id: 5, title: "Perfectionist", description: "100% completion rate for a week", icon: "💎", color: "bg-gradient-to-r from-purple-400 to-indigo-500", progress: 6, total: 7 },
]

const motivationalQuotes = [
  { text: "The only way to do great work is to love what you do.", author: "Steve Jobs", color: "from-purple-500 to-pink-500" },
  { text: "Innovation distinguishes between a leader and a follower.", author: "Steve Jobs", color: "from-blue-500 to-cyan-500" },
  { text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", color: "from-green-500 to-teal-500" },
  { text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", color: "from-orange-500 to-red-500" },
  { text: "The only impossible journey is the one you never begin.", author: "Tony Robbins", color: "from-indigo-500 to-purple-500" },
]

const teamMembers = [
  {
    id: 1,
    name: "Sarah Chen",
    role: "UI/UX Designer",
    avatar: "https://api.dicebear.com/9.x/avataaars/svg?seed=Sarah",
    email: "sarah.chen@example.com",
    tasksCompleted: 12,
    currentTask: "Design new landing page",
    productivity: 92,
    status: "online",
    achievements: ["Early Bird", "Design Master", "Team Player"]
  },
  {
    id: 2,
    name: "Alex Thompson",
    role: "Full Stack Developer",
    avatar: "https://api.dicebear.com/9.x/avataaars/svg?seed=Alex",
    email: "alex.thompson@example.com",
    tasksCompleted: 15,
    currentTask: "Fix authentication bug",
    productivity: 88,
    status: "busy",
    achievements: ["Code Ninja", "Bug Squasher", "Sprint Master"]
  },
  {
    id: 3,
    name: "Maria Garcia",
    role: "Technical Writer",
    avatar: "https://api.dicebear.com/9.x/avataaars/svg?seed=Maria",
    email: "maria.garcia@example.com",
    tasksCompleted: 8,
    currentTask: "Write API documentation",
    productivity: 95,
    status: "online",
    achievements: ["Documentation Hero", "Perfectionist", "Early Bird"]
  },
  {
    id: 4,
    name: "James Wilson",
    role: "Backend Developer",
    avatar: "https://api.dicebear.com/9.x/avataaars/svg?seed=James",
    email: "james.wilson@example.com",
    tasksCompleted: 10,
    currentTask: "Implement search feature",
    productivity: 82,
    status: "away",
    achievements: ["API Master", "Performance Guru", "Team Player"]
  },
  {
    id: 5,
    name: "Priya Patel",
    role: "DevOps Engineer",
    avatar: "https://api.dicebear.com/9.x/avataaars/svg?seed=Priya",
    email: "priya.patel@example.com",
    tasksCompleted: 18,
    currentTask: "Optimize database queries",
    productivity: 96,
    status: "online",
    achievements: ["Automation Expert", "Sprint Master", "Perfectionist"]
  }
]

export default function EnhancedDashboardSection() {
  const [date, setDate] = useState<Date | undefined>(new Date())
  const [selectedEmoji, setSelectedEmoji] = useState("")
  const [commandOpen, setCommandOpen] = useState(false)
  const [sheetOpen, setSheetOpen] = useState(false)
  const [selectedTaskForSheet, setSelectedTaskForSheet] = useState<any>(null)
  const [alertOpen, setAlertOpen] = useState(false)
  const [taskToComplete, setTaskToComplete] = useState<any>(null)
  const [achievementCarouselApi, setAchievementCarouselApi] = useState<any>(null)
  const [quotesCarouselApi, setQuotesCarouselApi] = useState<any>(null)
  
  // Collapsible states for different sections
  const [achievementsOpen, setAchievementsOpen] = useState(true)
  const [teamOpen, setTeamOpen] = useState(true)
  const [calendarOpen, setCalendarOpen] = useState(true)
  const [inspirationOpen, setInspirationOpen] = useState(true)

  // Keyboard shortcut for command palette
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        setCommandOpen((open) => {
          if (!open) {
            toast.info("⌨️ Command palette opened with Cmd+K (shadcn/ui Command component)")
          }
          return !open
        })
      }
    }
    document.addEventListener("keydown", down)
    return () => document.removeEventListener("keydown", down)
  }, [])

  // Carousel API listeners for educational toasts
  useEffect(() => {
    if (!achievementCarouselApi) return
    
    achievementCarouselApi.on("select", () => {
      toast.info("🎯 Achievement carousel navigated (shadcn/ui Carousel component)")
    })
  }, [achievementCarouselApi])

  useEffect(() => {
    if (!quotesCarouselApi) return
    
    quotesCarouselApi.on("select", () => {
      toast.info("✨ Inspirational quote changed (shadcn/ui Carousel component)")
    })
  }, [quotesCarouselApi])

  // Get tasks for selected date
  const tasksForDate = tasks.filter(task => {
    const taskDate = new Date(task.dueDate)
    return date && isSameDay(taskDate, date)
  })

  // Calendar with task indicators
  const tasksWithDates = tasks.reduce((acc, task) => {
    const date = format(new Date(task.dueDate), "yyyy-MM-dd")
    if (!acc[date]) acc[date] = []
    acc[date].push(task)
    return acc
  }, {} as Record<string, typeof tasks>)

  return (
    <TooltipProvider>
    <div className="space-y-6 p-4">
      <Head title="Enhanced Productivity Dashboard" />

      {/* Home Button */}
      <div className="flex justify-start">
        <Link href={rootPath()}>
          <Button 
            variant="outline" 
            size="sm" 
            className="flex items-center gap-2 hover:bg-primary hover:text-primary-foreground transition-colors"
            onClick={() => {
              toast.info("🏠 Returning to home page (Inertia.js Link + shadcn/ui Button)")
            }}
          >
            <Home className="h-4 w-4" />
            <span>Back to Home</span>
          </Button>
        </Link>
      </div>

      {/* Command Palette */}
      <CommandDialog open={commandOpen} onOpenChange={setCommandOpen}>
        <CommandInput placeholder="Type a command or search..." />
        <CommandList>
          <CommandEmpty>No results found.</CommandEmpty>
          <CommandGroup heading="Quick Actions">
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("📋 Demo Action: This would create a new task (shadcn/ui Command component)")
            }}>
              <Plus className="mr-2 h-4 w-4" />
              <span>Create New Task</span>
              <CommandShortcut>⌘N</CommandShortcut>
            </CommandItem>
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("🔍 Demo Action: This would open search (shadcn/ui Command component)")
            }}>
              <Search className="mr-2 h-4 w-4" />
              <span>Search Tasks</span>
              <CommandShortcut>⌘F</CommandShortcut>
            </CommandItem>
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("🎯 Demo Action: This would toggle focus mode (shadcn/ui Command component)")
            }}>
              <Target className="mr-2 h-4 w-4" />
              <span>Focus Mode</span>
              <CommandShortcut>⌘⏎</CommandShortcut>
            </CommandItem>
          </CommandGroup>
          <CommandSeparator />
          <CommandGroup heading="Team">
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("👤 Demo Action: This would open Sarah's profile (shadcn/ui Command component)")
            }}>
              <User className="mr-2 h-4 w-4" />
              <span>Sarah Chen</span>
            </CommandItem>
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("👤 Demo Action: This would open Alex's profile (shadcn/ui Command component)")
            }}>
              <User className="mr-2 h-4 w-4" />
              <span>Alex Thompson</span>
            </CommandItem>
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("👤 Demo Action: This would open Maria's profile (shadcn/ui Command component)")
            }}>
              <User className="mr-2 h-4 w-4" />
              <span>Maria Garcia</span>
            </CommandItem>
          </CommandGroup>
          <CommandSeparator />
          <CommandGroup heading="Settings">
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("⚙️ Demo Action: This would open profile settings (shadcn/ui Command component)")
            }}>
              <User className="mr-2 h-4 w-4" />
              <span>Profile</span>
              <CommandShortcut>⌘P</CommandShortcut>
            </CommandItem>
            <CommandItem onSelect={() => {
              setCommandOpen(false)
              toast.info("⚙️ Demo Action: This would open preferences (shadcn/ui Command component)")
            }}>
              <Settings className="mr-2 h-4 w-4" />
              <span>Preferences</span>
              <CommandShortcut>⌘,</CommandShortcut>
            </CommandItem>
          </CommandGroup>
        </CommandList>
      </CommandDialog>

      {/* Quick Access Button for Command Palette */}
      <div className="fixed top-4 right-4 z-50">
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setCommandOpen(true)
                toast.info("⌨️ Opened Command Palette (shadcn/ui Command component)")
              }}
              className="gap-2"
            >
              <CommandIcon className="h-4 w-4" />
              <span className="hidden sm:inline">Quick Actions</span>
              <kbd className="pointer-events-none inline-flex h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium text-muted-foreground opacity-100">
                <span className="text-xs">⌘</span>K
              </kbd>
            </Button>
          </TooltipTrigger>
          <TooltipContent>
            <p>Open command palette for quick actions</p>
          </TooltipContent>
        </Tooltip>
      </div>

      {/* Achievement Carousel */}
      <Collapsible open={achievementsOpen} onOpenChange={setAchievementsOpen}>
        <Card>
          <CardHeader>
            <CollapsibleTrigger asChild>
              <div 
                className="flex items-center justify-between cursor-pointer hover:opacity-80 transition-opacity"
                onClick={() => {
                  toast.info(`📱 ${achievementsOpen ? 'Collapsing' : 'Expanding'} section (shadcn/ui Collapsible component)`)
                }}
              >
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Trophy className="h-5 w-5 text-yellow-500" />
                    Achievement Showcase
                  </CardTitle>
                  <CardDescription>Your productivity milestones</CardDescription>
                </div>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button variant="ghost" size="sm">
                      {achievementsOpen ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent>
                    <p>{achievementsOpen ? "Collapse section" : "Expand section"}</p>
                  </TooltipContent>
                </Tooltip>
              </div>
            </CollapsibleTrigger>
          </CardHeader>
          <CollapsibleContent>
            <CardContent>
              <Carousel className="w-full max-w-4xl mx-auto" setApi={setAchievementCarouselApi}>
            <CarouselContent>
              {achievements.map((achievement) => (
                <CarouselItem key={achievement.id} className="md:basis-1/2 lg:basis-1/3">
                  <Card className={`${achievement.color} text-white border-0`}>
                    <CardContent className="flex flex-col items-center justify-center p-6">
                      <div className="text-4xl mb-2">{achievement.icon}</div>
                      <h3 className="font-bold text-lg">{achievement.title}</h3>
                      <p className="text-sm opacity-90 text-center">{achievement.description}</p>
                      <div className="mt-4 w-full bg-white/20 rounded-full h-2">
                        <div 
                          className="bg-white h-2 rounded-full transition-all"
                          style={{ width: `${(achievement.progress / achievement.total) * 100}%` }}
                        />
                      </div>
                      <span className="text-xs mt-2">{achievement.progress}/{achievement.total}</span>
                      {achievement.progress === achievement.total && (
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Badge className="mt-2 bg-white text-black">Completed!</Badge>
                          </TooltipTrigger>
                          <TooltipContent>
                            <p>🎉 You&apos;ve unlocked this achievement!</p>
                          </TooltipContent>
                        </Tooltip>
                      )}
                    </CardContent>
                  </Card>
                </CarouselItem>
              ))}
            </CarouselContent>
            <CarouselPrevious />
            <CarouselNext />
          </Carousel>
            </CardContent>
          </CollapsibleContent>
        </Card>
      </Collapsible>

      {/* Team Showcase with Hover Cards */}
      <Collapsible open={teamOpen} onOpenChange={setTeamOpen}>
        <Card>
          <CardHeader>
            <CollapsibleTrigger asChild>
              <div 
                className="flex items-center justify-between cursor-pointer hover:opacity-80 transition-opacity"
                onClick={() => {
                  toast.info(`👥 ${teamOpen ? 'Collapsing' : 'Expanding'} team section (shadcn/ui Collapsible component)`)
                }}
              >
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <User className="h-5 w-5" />
                    Team Members
                  </CardTitle>
                  <CardDescription>Hover over team members to see their stats</CardDescription>
                </div>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button variant="ghost" size="sm">
                      {teamOpen ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent>
                    <p>{teamOpen ? "Collapse section" : "Expand section"}</p>
                  </TooltipContent>
                </Tooltip>
              </div>
            </CollapsibleTrigger>
          </CardHeader>
          <CollapsibleContent>
            <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {teamMembers.map((member) => (
              <HoverCard key={member.id}>
                <HoverCardTrigger asChild>
                  <div 
                    className="cursor-pointer"
                    onMouseEnter={() => {
                      toast.info(`👤 Hovering over ${member.name} (shadcn/ui HoverCard component)`)
                    }}
                  >
                    <div className="flex flex-col items-center space-y-2 p-3 rounded-lg hover:bg-accent transition-colors">
                      <Avatar className="h-12 w-12">
                        <AvatarImage src={member.avatar} alt={member.name} />
                        <AvatarFallback>{member.name.split(' ').map(n => n[0]).join('')}</AvatarFallback>
                      </Avatar>
                      <div className="text-center">
                        <p className="font-medium text-sm">{member.name}</p>
                        <p className="text-xs text-muted-foreground">{member.role}</p>
                      </div>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <div className="flex items-center gap-1">
                            <div className={`h-2 w-2 rounded-full ${
                              member.status === 'online' ? 'bg-green-500' :
                              member.status === 'busy' ? 'bg-red-500' :
                              'bg-yellow-500'
                            }`} />
                            <span className="text-xs text-muted-foreground">{member.status}</span>
                          </div>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>{member.status === 'online' ? 'Available for collaboration' : 
                             member.status === 'busy' ? 'In focus mode - do not disturb' : 
                             'Away from desk'}</p>
                        </TooltipContent>
                      </Tooltip>
                    </div>
                  </div>
                </HoverCardTrigger>
                <HoverCardContent className="w-80">
                  <div className="space-y-4">
                    <div className="flex items-start gap-4">
                      <Avatar className="h-14 w-14">
                        <AvatarImage src={member.avatar} alt={member.name} />
                        <AvatarFallback>{member.name.split(' ').map(n => n[0]).join('')}</AvatarFallback>
                      </Avatar>
                      <div className="space-y-1">
                        <h4 className="text-sm font-semibold">{member.name}</h4>
                        <p className="text-sm text-muted-foreground">{member.role}</p>
                        <p className="text-xs text-muted-foreground">{member.email}</p>
                      </div>
                    </div>
                    
                    <div className="space-y-2">
                      <div className="flex justify-between items-center">
                        <span className="text-sm text-muted-foreground">Productivity</span>
                        <span className="text-sm font-medium">{member.productivity}%</span>
                      </div>
                      <div className="w-full bg-secondary rounded-full h-2">
                        <div 
                          className="bg-gradient-to-r from-green-400 to-blue-500 h-2 rounded-full transition-all"
                          style={{ width: `${member.productivity}%` }}
                        />
                      </div>
                    </div>

                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <CheckCircle2 className="h-4 w-4 text-green-500" />
                        <span className="text-sm">
                          <strong>{member.tasksCompleted}</strong> tasks completed this week
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Target className="h-4 w-4 text-blue-500" />
                        <span className="text-sm">
                          Currently: <strong>{member.currentTask}</strong>
                        </span>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <p className="text-xs font-medium text-muted-foreground">Achievements</p>
                      <div className="flex flex-wrap gap-1">
                        {member.achievements.map((achievement, idx) => (
                          <Badge key={idx} variant="secondary" className="text-xs">
                            {achievement}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  </div>
                </HoverCardContent>
              </HoverCard>
            ))}
          </div>
            </CardContent>
          </CollapsibleContent>
        </Card>
      </Collapsible>

      {/* Calendar with Popover */}
      <Collapsible open={calendarOpen} onOpenChange={setCalendarOpen}>
          <Card>
            <CardHeader>
              <CollapsibleTrigger asChild>
                <div 
                  className="flex items-center justify-between cursor-pointer hover:opacity-80 transition-opacity"
                  onClick={() => {
                    toast.info(`📅 ${calendarOpen ? 'Collapsing' : 'Expanding'} calendar section (shadcn/ui Collapsible component)`)
                  }}
                >
                  <div>
                    <CardTitle className="flex items-center gap-2">
                      <CalendarIcon className="h-5 w-5" />
                      Task Calendar
                    </CardTitle>
                    <CardDescription>Click on dates to see tasks</CardDescription>
                  </div>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button variant="ghost" size="sm">
                        {calendarOpen ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>
                      <p>{calendarOpen ? "Collapse section" : "Expand section"}</p>
                    </TooltipContent>
                  </Tooltip>
                </div>
              </CollapsibleTrigger>
            </CardHeader>
            <CollapsibleContent>
              <CardContent>
            <Popover>
              <PopoverTrigger asChild>
                <Button 
                  variant="outline" 
                  className="w-full justify-start text-left font-normal mb-4"
                  onClick={() => {
                    toast.info("📅 Opening calendar (shadcn/ui Popover + Calendar components)")
                  }}
                >
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {date ? format(date, "PPP") : <span>Pick a date</span>}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={date}
                  onSelect={(newDate) => {
                    setDate(newDate)
                    if (newDate) {
                      toast.info("📅 Date selected (shadcn/ui Calendar component)")
                    }
                  }}
                  initialFocus
                  modifiers={{
                    hasTasks: Object.keys(tasksWithDates).map(d => new Date(d))
                  }}
                  modifiersClassNames={{
                    hasTasks: "bg-blue-100 dark:bg-blue-900 font-bold"
                  }}
                />
              </PopoverContent>
            </Popover>

            {/* Tasks for selected date */}
            <div className="space-y-2">
              <h4 className="font-semibold text-sm">Tasks for {date && format(date, "MMM dd, yyyy")}</h4>
              {tasksForDate.length > 0 ? (
                tasksForDate.map(task => (
                  <ContextMenu key={task.id}>
                    <ContextMenuTrigger>
                      <div 
                        className="p-3 border rounded-lg hover:bg-accent cursor-pointer"
                        onClick={() => {
                          setSelectedTaskForSheet(task)
                          setSheetOpen(true)
                          toast.info("📋 Opening task details (shadcn/ui Sheet component)")
                        }}
                        onContextMenu={() => {
                          toast.info("🖱️ Right-click detected (shadcn/ui ContextMenu component)")
                        }}
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-medium">{task.title}</span>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Badge variant={task.priority === "urgent" ? "destructive" : "secondary"}>
                                {task.priority}
                              </Badge>
                            </TooltipTrigger>
                            <TooltipContent>
                              <p>{task.priority === "urgent" ? "⚡ Needs immediate attention" : 
                                 task.priority === "high" ? "⬆️ Important task" : 
                                 "➡️ Regular priority"}</p>
                            </TooltipContent>
                          </Tooltip>
                        </div>
                      </div>
                    </ContextMenuTrigger>
                    <ContextMenuContent>
                      <ContextMenuItem onClick={() => {
                        setSelectedTaskForSheet(task)
                        setSheetOpen(true)
                        toast.info("📋 Demo Action: Opening task details (shadcn/ui ContextMenu + Sheet components)")
                      }}>
                        <Info className="mr-2 h-4 w-4" />
                        View Details
                        <ContextMenuShortcut>⌘I</ContextMenuShortcut>
                      </ContextMenuItem>
                      <ContextMenuItem onClick={() => {
                        setTaskToComplete(task)
                        setAlertOpen(true)
                        toast.info("✅ Demo Action: Opening completion dialog (shadcn/ui ContextMenu + AlertDialog components)")
                      }}>
                        <CheckCircle2 className="mr-2 h-4 w-4" />
                        Complete
                        <ContextMenuShortcut>⌘K</ContextMenuShortcut>
                      </ContextMenuItem>
                      <ContextMenuItem onClick={() => toast.info("✏️ Demo Action: This would open task editor (shadcn/ui ContextMenu component)")}>
                        <Edit className="mr-2 h-4 w-4" />
                        Edit
                        <ContextMenuShortcut>⌘E</ContextMenuShortcut>
                      </ContextMenuItem>
                      <ContextMenuSeparator />
                      <ContextMenuSub>
                        <ContextMenuSubTrigger>
                          <Heart className="mr-2 h-4 w-4" />
                          Add Reaction
                        </ContextMenuSubTrigger>
                        <ContextMenuSubContent>
                          <ContextMenuRadioGroup value={selectedEmoji}>
                            <ContextMenuRadioItem value="👍" onClick={() => { setSelectedEmoji("👍"); toast.info("👍 Demo Action: Added reaction (shadcn/ui ContextMenu sub-menu)") }}>
                              👍 Like
                            </ContextMenuRadioItem>
                            <ContextMenuRadioItem value="❤️" onClick={() => { setSelectedEmoji("❤️"); toast.info("❤️ Demo Action: Added reaction (shadcn/ui ContextMenu sub-menu)") }}>
                              ❤️ Love
                            </ContextMenuRadioItem>
                            <ContextMenuRadioItem value="🎉" onClick={() => { setSelectedEmoji("🎉"); toast.info("🎉 Demo Action: Added reaction (shadcn/ui ContextMenu sub-menu)") }}>
                              🎉 Celebrate
                            </ContextMenuRadioItem>
                            <ContextMenuRadioItem value="🚀" onClick={() => { setSelectedEmoji("🚀"); toast.info("🚀 Demo Action: Added reaction (shadcn/ui ContextMenu sub-menu)") }}>
                              🚀 Ship it!
                            </ContextMenuRadioItem>
                          </ContextMenuRadioGroup>
                        </ContextMenuSubContent>
                      </ContextMenuSub>
                      <ContextMenuItem onClick={() => toast.info("📋 Demo Action: This would duplicate the task (shadcn/ui ContextMenu component)")}>
                        <Copy className="mr-2 h-4 w-4" />
                        Duplicate
                      </ContextMenuItem>
                      <ContextMenuSeparator />
                      <ContextMenuItem className="text-red-600" onClick={() => toast.error("🗑️ Demo Action: This would delete the task (shadcn/ui ContextMenu component)")}>
                        <Trash className="mr-2 h-4 w-4" />
                        Delete
                        <ContextMenuShortcut>⌘D</ContextMenuShortcut>
                      </ContextMenuItem>
                    </ContextMenuContent>
                  </ContextMenu>
                ))
              ) : (
                <p className="text-sm text-muted-foreground">No tasks for this date</p>
              )}
            </div>
              </CardContent>
            </CollapsibleContent>
          </Card>
        </Collapsible>

      {/* Motivational Quotes Carousel */}
      <Collapsible open={inspirationOpen} onOpenChange={setInspirationOpen}>
        <Card>
          <CardHeader>
            <CollapsibleTrigger asChild>
              <div 
                className="flex items-center justify-between cursor-pointer hover:opacity-80 transition-opacity"
                onClick={() => {
                  toast.info(`✨ ${inspirationOpen ? 'Collapsing' : 'Expanding'} inspiration section (shadcn/ui Collapsible component)`)
                }}
              >
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Sparkles className="h-5 w-5" />
                    Daily Inspiration
                  </CardTitle>
                </div>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button variant="ghost" size="sm">
                      {inspirationOpen ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent>
                    <p>{inspirationOpen ? "Collapse section" : "Expand section"}</p>
                  </TooltipContent>
                </Tooltip>
              </div>
            </CollapsibleTrigger>
          </CardHeader>
          <CollapsibleContent>
            <CardContent>
          <Carousel className="w-full max-w-2xl mx-auto" setApi={setQuotesCarouselApi}>
            <CarouselContent>
              {motivationalQuotes.map((quote, index) => (
                <CarouselItem key={index}>
                  <Card className={`bg-gradient-to-r ${quote.color} text-white border-0`}>
                    <CardContent className="flex flex-col items-center justify-center p-8 text-center">
                      <Sparkles className="h-8 w-8 mb-4" />
                      <blockquote className="text-lg font-medium italic">
                        &quot;{quote.text}&quot;
                      </blockquote>
                      <cite className="mt-4 text-sm opacity-90">— {quote.author}</cite>
                    </CardContent>
                  </Card>
                </CarouselItem>
              ))}
            </CarouselContent>
            <CarouselPrevious />
            <CarouselNext />
          </Carousel>
            </CardContent>
          </CollapsibleContent>
        </Card>
      </Collapsible>

      {/* Task Details Sheet */}
      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <SheetContent className="w-full sm:max-w-xl">
          <SheetHeader>
            <SheetTitle>Task Details</SheetTitle>
            <SheetDescription>
              View and manage task information
            </SheetDescription>
          </SheetHeader>
          {selectedTaskForSheet && (
            <div className="mt-6 space-y-6">
              <div className="space-y-2">
                <h3 className="text-lg font-semibold">{selectedTaskForSheet.title}</h3>
                <Badge variant={selectedTaskForSheet.priority === "urgent" ? "destructive" : 
                  selectedTaskForSheet.priority === "high" ? "default" : "secondary"}>
                  {selectedTaskForSheet.priority} priority
                </Badge>
              </div>

              <div className="space-y-2">
                <Label>Description</Label>
                <p className="text-sm text-muted-foreground">
                  {selectedTaskForSheet.description ?? "No description available"}
                </p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Status</Label>
                  <div className="flex items-center gap-2">
                    <Circle className="h-4 w-4" />
                    <span className="text-sm">{selectedTaskForSheet.status}</span>
                  </div>
                </div>
                <div className="space-y-2">
                  <Label>Due Date</Label>
                  <div className="flex items-center gap-2">
                    <CalendarIcon className="h-4 w-4" />
                    <span className="text-sm">{selectedTaskForSheet.dueDate}</span>
                  </div>
                </div>
              </div>

              {selectedTaskForSheet.assignee && (
                <div className="space-y-2">
                  <Label>Assigned To</Label>
                  <div className="flex items-center gap-3">
                    <Avatar className="h-8 w-8">
                      <AvatarImage src={selectedTaskForSheet.assignee.avatar} />
                      <AvatarFallback>
                        {selectedTaskForSheet.assignee.name.split(' ').map((n: string) => n[0]).join('')}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="text-sm font-medium">{selectedTaskForSheet.assignee.name}</p>
                      <p className="text-xs text-muted-foreground">{selectedTaskForSheet.assignee.role}</p>
                    </div>
                  </div>
                </div>
              )}

              <div className="space-y-2">
                <Label>Progress</Label>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Completion</span>
                    <span>{selectedTaskForSheet.progress || 0}%</span>
                  </div>
                  <div className="w-full bg-secondary rounded-full h-2">
                    <div 
                      className="bg-gradient-to-r from-blue-400 to-green-500 h-2 rounded-full transition-all"
                      style={{ width: `${selectedTaskForSheet.progress || 0}%` }}
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label>Tags</Label>
                <div className="flex flex-wrap gap-2">
                  {selectedTaskForSheet.tags?.map((tag: string, idx: number) => (
                    <Badge key={idx} variant="outline" className="text-xs">
                      {tag}
                    </Badge>
                  )) || <span className="text-sm text-muted-foreground">No tags</span>}
                </div>
              </div>

              <div className="flex gap-2 pt-4">
                <Button 
                  className="flex-1" 
                  onClick={() => {
                    toast.success("✅ Demo Action: This would mark task as complete (shadcn/ui Sheet component)")
                    setSheetOpen(false)
                  }}
                >
                  <CheckCircle2 className="mr-2 h-4 w-4" />
                  Complete Task
                </Button>
                <Button 
                  variant="outline" 
                  className="flex-1"
                  onClick={() => {
                    toast.info("✏️ Demo Action: This would open task editor (shadcn/ui Sheet component)")
                    setSheetOpen(false)
                  }}
                >
                  <Edit className="mr-2 h-4 w-4" />
                  Edit Task
                </Button>
              </div>
            </div>
          )}
        </SheetContent>
      </Sheet>

      {/* Task Completion Alert Dialog */}
      <AlertDialog open={alertOpen} onOpenChange={setAlertOpen}>
        <AlertDialogContent className="max-w-md">
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <Sparkles className="h-5 w-5 text-yellow-500 animate-pulse" />
              Complete Task?
              <Sparkles className="h-5 w-5 text-yellow-500 animate-pulse" />
            </AlertDialogTitle>
            <AlertDialogDescription>
              {taskToComplete && (
                <div className="space-y-3">
                  <p className="text-base">
                    You&apos;re about to complete: <strong>{taskToComplete.title}</strong>
                  </p>
                  <div className="flex justify-center gap-2 text-3xl animate-bounce">
                    🎉 🎊 🏆
                  </div>
                  <p className="text-sm text-center">
                    Great job! You&apos;re making amazing progress today!
                  </p>
                </div>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setTaskToComplete(null)}>
              Not yet
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                toast.success(
                  <div className="flex items-center gap-2">
                    <Trophy className="h-4 w-4 text-yellow-500" />
                    <span>Task completed! Keep up the great work! 🎉</span>
                  </div>
                )
                setTaskToComplete(null)
                // Add confetti or celebration animation here
                if (typeof window !== 'undefined') {
                  // Create a simple confetti effect
                  const duration = 3 * 1000;
                  const animationEnd = Date.now() + duration;
                  const interval = setInterval(function() {
                    const timeLeft = animationEnd - Date.now();

                    if (timeLeft <= 0) {
                      return clearInterval(interval);
                    }

                    // Create custom confetti effect here (simplified version)
                    console.log('🎉 Confetti! 🎊');
                  }, 250);
                }
              }}
              className="bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600"
            >
              Complete! 🎯
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
    </TooltipProvider>
  )
}