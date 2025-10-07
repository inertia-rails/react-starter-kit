import { Head } from '@inertiajs/react';
import { AlertCircle, CheckCircle, Clock, Database, Download, Layers, Package, Play, RefreshCw, Users } from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import AppLayout from '@/layouts/app-layout';

interface DashboardProps {
  stats: {
    users_count: number;
    cards_count: number;
    card_sets_count: number;
    card_printings_count: number;
    card_faces_count: number;
    card_rulings_count: number;
    card_legalities_count: number;
    related_cards_count: number;
    scryfall_syncs_count: number;
    open_search_syncs_count: number;
    search_evals_count: number;
    embedding_runs_count: number;
  };
  recent_users: {
    id: number;
    name: string;
    email: string;
    created_at: string;
    verified: boolean;
    admin: boolean;
  }[];
  sync_status: {
    sync_type: string;
    status: string;
    version: string | null;
    completed_at: string | null;
    processing_status: string | null;
    total_records: number | null;
    processed_records: number | null;
  }[];
  open_search_sync_status: {
    recent_sync: {
      id: number;
      status: string;
      total_cards: number;
      indexed_cards: number;
      failed_cards: number;
      progress_percentage: number;
      started_at: string | null;
      completed_at: string | null;
      duration_formatted: string | null;
      error_message: string | null;
    } | null;
    index_stats: {
      document_count?: number;
      size_in_bytes?: number;
    };
  };
  search_eval_status: {
    recent_eval: {
      id: number;
      status: string;
      eval_type: string;
      total_queries: number;
      completed_queries: number;
      failed_queries: number;
      progress_percentage: number;
      avg_precision: number | null;
      avg_recall: number | null;
      avg_mrr: number | null;
      avg_ndcg: number | null;
      use_llm_judge: boolean;
      started_at: string | null;
      completed_at: string | null;
      duration_formatted: string | null;
      error_message: string | null;
    } | null;
  };
  embedding_run_status: {
    recent_run: {
      id: number;
      status: string;
      total_cards: number;
      processed_cards: number;
      failed_cards: number;
      batch_size: number;
      progress_percentage: number;
      started_at: string | null;
      completed_at: string | null;
      duration_formatted: string | null;
      error_message: string | null;
    } | null;
    embedding_coverage: {
      total_cards: number;
      cards_with_embeddings: number;
      percentage: number;
    };
  };
}

interface LiveSyncData {
  id: number;
  sync_type: string;
  status: string;
  processing_status: string;
  job_progress: {
    total: number;
    completed: number;
    failed: number;
    pending: number;
    percentage: number;
  };
  processing_progress: {
    total_records: number | null;
    processed_records: number;
    percentage: number;
    failed_batches: number;
  };
  estimated_completion: string | null;
}

interface SyncDetails {
  sync: {
    id: number;
    sync_type: string;
    status: string;
    error_message: string | null;
    failure_logs: {
      timestamp: string;
      error: string;
      batch_number: number | null;
      context: Record<string, any>;
    }[];
    job_progress: {
      total: number;
      completed: number;
      failed: number;
      pending: number;
      percentage: number;
    };
  };
}

export default function Dashboard({ stats, recent_users, sync_status, open_search_sync_status, search_eval_status, embedding_run_status }: DashboardProps) {
  const [liveSyncs, setLiveSyncs] = useState<LiveSyncData[]>([]);
  const [selectedSync, setSelectedSync] = useState<number | null>(null);
  const [syncDetails, setSyncDetails] = useState<SyncDetails | null>(null);
  const [isPolling, setIsPolling] = useState(false);
  const [syncToStart, setSyncToStart] = useState<string | null>(null);
  const [isStartingSyncs, setIsStartingSyncs] = useState<Record<string, boolean>>({});
  const [isStartingOpenSearchReindex, setIsStartingOpenSearchReindex] = useState(false);
  const [isStartingSearchEval, setIsStartingSearchEval] = useState(false);
  const [isStartingEmbeddingRun, setIsStartingEmbeddingRun] = useState(false);
  const [evalTypeToStart, setEvalTypeToStart] = useState<'keyword' | 'semantic' | 'hybrid'>('keyword');
  const [useLLMJudge, setUseLLMJudge] = useState(false);

  // Fetch live sync progress
  const fetchSyncProgress = useCallback(async () => {
    try {
      const response = await fetch('/admin/scryfall_syncs/progress');
      if (response.ok) {
        const data = await response.json();
        setLiveSyncs(data.syncs);

        // Check if any syncs are still processing
        const hasActiveSyncs = data.syncs.some((sync: LiveSyncData) =>
          sync.status === 'downloading' || sync.processing_status === 'processing'
        );
        setIsPolling(hasActiveSyncs);
      }
    } catch (error) {
      console.error('Failed to fetch sync progress:', error);
    }
  }, []);

  // Fetch detailed sync information
  const fetchSyncDetails = useCallback(async (syncId: number) => {
    try {
      const response = await fetch(`/admin/scryfall_syncs/${syncId}`);
      if (response.ok) {
        const data = await response.json();
        setSyncDetails(data);
        setSelectedSync(syncId);
      }
    } catch (error) {
      console.error('Failed to fetch sync details:', error);
    }
  }, []);

  // Start a sync
  const startSync = useCallback(async (syncType: string) => {
    setIsStartingSyncs(prev => ({ ...prev, [syncType]: true }));

    try {
      const response = await fetch('/admin/scryfall_syncs/start', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
        },
        body: JSON.stringify({ sync_type: syncType }),
      });

      const data = await response.json();

      if (data.success) {
        // Refresh sync progress immediately
        fetchSyncProgress();
        // Show success message (you could add a toast notification here)
        console.log(`Sync started for ${syncType}`);
      } else {
        // Show error message
        alert(data.message || 'Failed to start sync');
      }
    } catch (error) {
      console.error('Failed to start sync:', error);
      alert('Failed to start sync');
    } finally {
      setIsStartingSyncs(prev => ({ ...prev, [syncType]: false }));
      setSyncToStart(null);
    }
  }, [fetchSyncProgress]);

  // Polling effect
  useEffect(() => {
    fetchSyncProgress();

    const interval = setInterval(() => {
      if (isPolling) {
        fetchSyncProgress();
      }
    }, 2000); // Poll every 2 seconds

    return () => clearInterval(interval);
  }, [fetchSyncProgress, isPolling]);

  // Refresh selected sync details if modal is open
  useEffect(() => {
    if (selectedSync && isPolling) {
      const interval = setInterval(() => {
        fetchSyncDetails(selectedSync);
      }, 2000);

      return () => clearInterval(interval);
    }
  }, [selectedSync, isPolling, fetchSyncDetails]);

  const getStatusBadge = (status: string) => {
    const variants: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
      completed: 'default',
      failed: 'destructive',
      downloading: 'secondary',
      pending: 'outline',
      never_synced: 'outline',
      processing: 'secondary',
      queued: 'outline',
    };
    const displayText = status === 'never_synced' ? 'Never Synced' : status;
    return <Badge variant={variants[status] || 'outline'}>{displayText}</Badge>;
  };

  const formatTime = (timestamp: string) => {
    return new Date(timestamp).toLocaleString();
  };

  // Merge live data with static data
  const mergedSyncStatus = sync_status.map(sync => {
    const liveSync = liveSyncs.find(ls => ls.sync_type === sync.sync_type);
    return liveSync ? { ...sync, ...liveSync } : sync;
  });

  // Check if a sync can be started
  const canStartSync = (sync: any) => {
    return sync.status !== 'downloading' && sync.processing_status !== 'processing' && sync.processing_status !== 'queued';
  };

  return (
    <AppLayout>
      <Head title="Admin Dashboard" />

      <div className="p-6 space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold">Admin Dashboard</h1>
            <p className="text-muted-foreground">Overview of your application's data and status</p>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={() => fetchSyncProgress()}
            className="gap-2"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </Button>
        </div>

        {/* Statistics Cards */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Users</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.users_count.toLocaleString()}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Cards (Oracle)</CardTitle>
              <Package className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.cards_count.toLocaleString()}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Card Sets</CardTitle>
              <Layers className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.card_sets_count.toLocaleString()}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Card Printings</CardTitle>
              <Database className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.card_printings_count.toLocaleString()}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Card Faces</CardTitle>
              <Layers className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.card_faces_count.toLocaleString()}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Card Rulings</CardTitle>
              <Database className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.card_rulings_count.toLocaleString()}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Card Legalities</CardTitle>
              <Database className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.card_legalities_count.toLocaleString()}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Related Cards</CardTitle>
              <Layers className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.related_cards_count.toLocaleString()}</div>
            </CardContent>
          </Card>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          {/* Recent Users */}
          <Card>
            <CardHeader>
              <CardTitle>Recent Users</CardTitle>
              <CardDescription>Latest users who have signed up</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {recent_users.map((user) => (
                  <div key={user.id} className="flex items-center justify-between space-x-4">
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate">{user.name}</p>
                      <p className="text-xs text-muted-foreground truncate">{user.email}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      {user.admin && <Badge variant="secondary">Admin</Badge>}
                      {user.verified ? (
                        <Badge variant="default">Verified</Badge>
                      ) : (
                        <Badge variant="outline">Unverified</Badge>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Scryfall Sync Status */}
          <Card>
            <CardHeader>
              <CardTitle>Scryfall Sync Status</CardTitle>
              <CardDescription>
                Current status of data synchronization
                {isPolling && (
                  <span className="ml-2 text-xs text-green-600">● Live updating</span>
                )}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {mergedSyncStatus.map((sync: any) => (
                  <div key={sync.sync_type} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <button
                          onClick={() => sync.id && fetchSyncDetails(sync.id)}
                          className="text-sm font-medium hover:underline cursor-pointer text-left"
                        >
                          {sync.sync_type.replace(/_/g, ' ')}
                        </button>
                        {sync.version && (
                          <p className="text-xs text-muted-foreground">Version: {sync.version}</p>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        {canStartSync(sync) && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setSyncToStart(sync.sync_type)}
                            disabled={isStartingSyncs[sync.sync_type]}
                            className="h-7 px-2"
                          >
                            {isStartingSyncs[sync.sync_type] ? (
                              <RefreshCw className="h-3 w-3 animate-spin" />
                            ) : (
                              <Play className="h-3 w-3" />
                            )}
                            <span className="ml-1 hidden sm:inline">Sync</span>
                          </Button>
                        )}
                        {getStatusBadge(sync.status)}
                        {sync.processing_status && sync.processing_status !== 'completed' && (
                          <Badge variant="outline">{sync.processing_status}</Badge>
                        )}
                        {sync.job_progress && sync.job_progress.failed > 0 && (
                          <Badge variant="destructive" className="gap-1">
                            <AlertCircle className="h-3 w-3" />
                            {sync.job_progress.failed}
                          </Badge>
                        )}
                      </div>
                    </div>

                    {/* Job Progress Bar */}
                    {sync.job_progress && sync.job_progress.total > 0 && (
                      <div className="space-y-1">
                        <div className="flex justify-between text-xs text-muted-foreground">
                          <span>Jobs: {sync.job_progress.completed}/{sync.job_progress.total}</span>
                          <span>{sync.job_progress.percentage.toFixed(1)}%</span>
                        </div>
                        <div className="w-full bg-secondary rounded-full h-2">
                          <div
                            className="bg-primary h-2 rounded-full transition-all"
                            style={{ width: `${sync.job_progress.percentage}%` }}
                          />
                        </div>
                      </div>
                    )}

                    {/* Processing Progress Bar */}
                    {sync.processing_status === 'processing' && sync.processing_progress && (
                      <div className="space-y-1">
                        <div className="flex justify-between text-xs text-muted-foreground">
                          <span>Records: {sync.processing_progress.processed_records}/{sync.processing_progress.total_records}</span>
                          <span>{sync.processing_progress.percentage.toFixed(1)}%</span>
                        </div>
                        <div className="w-full bg-secondary rounded-full h-2">
                          <div
                            className="bg-primary h-2 rounded-full transition-all"
                            style={{ width: `${sync.processing_progress.percentage}%` }}
                          />
                        </div>
                        {sync.estimated_completion && (
                          <p className="text-xs text-muted-foreground flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            Est. completion: {formatTime(sync.estimated_completion)}
                          </p>
                        )}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* OpenSearch Index Status */}
          <Card>
            <CardHeader>
              <CardTitle>OpenSearch Index Status</CardTitle>
              <CardDescription>Card search index status and reindexing</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {/* Index Stats */}
                <div className="grid grid-cols-2 gap-4 p-3 bg-muted/50 rounded-lg">
                  <div>
                    <p className="text-xs text-muted-foreground">Indexed Cards</p>
                    <p className="text-lg font-bold">
                      {(open_search_sync_status.index_stats.document_count ?? 0).toLocaleString()}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">Index Size</p>
                    <p className="text-lg font-bold">
                      {((open_search_sync_status.index_stats.size_in_bytes ?? 0) / 1024 / 1024).toFixed(2)} MB
                    </p>
                  </div>
                </div>

                {/* Recent Sync Status */}
                {open_search_sync_status.recent_sync ? (
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium">Last Reindex</p>
                      {getStatusBadge(open_search_sync_status.recent_sync.status)}
                    </div>

                    {/* Progress Bar */}
                    {open_search_sync_status.recent_sync.status === 'indexing' && (
                      <div className="space-y-1">
                        <div className="flex justify-between text-xs text-muted-foreground">
                          <span>
                            {(open_search_sync_status.recent_sync.indexed_cards ?? 0).toLocaleString()}/
                            {(open_search_sync_status.recent_sync.total_cards ?? 0).toLocaleString()} cards
                          </span>
                          <span>{(open_search_sync_status.recent_sync.progress_percentage ?? 0).toFixed(1)}%</span>
                        </div>
                        <div className="w-full bg-secondary rounded-full h-2">
                          <div
                            className="bg-primary h-2 rounded-full transition-all"
                            style={{ width: `${open_search_sync_status.recent_sync.progress_percentage}%` }}
                          />
                        </div>
                      </div>
                    )}

                    {/* Completed Info */}
                    {open_search_sync_status.recent_sync.status === 'completed' && (
                      <div className="text-xs text-muted-foreground space-y-1">
                        <p>Completed: {open_search_sync_status.recent_sync.completed_at}</p>
                        <p>Duration: {open_search_sync_status.recent_sync.duration_formatted}</p>
                        <p>Cards indexed: {(open_search_sync_status.recent_sync.indexed_cards ?? 0).toLocaleString()}</p>
                      </div>
                    )}

                    {/* Error Info */}
                    {open_search_sync_status.recent_sync.error_message && (
                      <div className="rounded-lg border border-destructive bg-destructive/10 p-2">
                        <p className="text-xs text-destructive">{open_search_sync_status.recent_sync.error_message}</p>
                      </div>
                    )}

                    {/* Failed Cards Warning */}
                    {open_search_sync_status.recent_sync.failed_cards > 0 && (
                      <div className="flex items-center gap-2 text-xs text-yellow-600">
                        <AlertCircle className="h-3 w-3" />
                        <span>{open_search_sync_status.recent_sync.failed_cards} cards failed to index</span>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-sm text-muted-foreground">No reindex operations yet</p>
                )}

                {/* Reindex Button */}
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full"
                  disabled={isStartingOpenSearchReindex || open_search_sync_status.recent_sync?.status === 'indexing'}
                  onClick={async () => {
                    setIsStartingOpenSearchReindex(true);
                    try {
                      const response = await fetch('/admin/open_search_syncs', {
                        method: 'POST',
                        headers: {
                          'Content-Type': 'application/json',
                          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                        },
                      });
                      const data = await response.json();
                      if (response.ok) {
                        window.location.reload();
                      } else {
                        alert(data.error || 'Failed to start reindex');
                      }
                    } catch (error) {
                      console.error('Failed to start reindex:', error);
                      alert('Failed to start reindex');
                    } finally {
                      setIsStartingOpenSearchReindex(false);
                    }
                  }}
                >
                  {isStartingOpenSearchReindex ? (
                    <>
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                      Starting...
                    </>
                  ) : (
                    <>
                      <RefreshCw className="h-4 w-4 mr-2" />
                      Start Reindex
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Search Quality Evals */}
          <Card>
            <CardHeader>
              <CardTitle>Search Quality Evals</CardTitle>
              <CardDescription>Evaluate search quality with test queries</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {search_eval_status.recent_eval ? (
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium">Last Eval ({search_eval_status.recent_eval.eval_type})</p>
                      {getStatusBadge(search_eval_status.recent_eval.status)}
                    </div>

                    {/* Progress Bar */}
                    {search_eval_status.recent_eval.status === 'running' && (
                      <div className="space-y-1">
                        <div className="flex justify-between text-xs text-muted-foreground">
                          <span>
                            {search_eval_status.recent_eval.completed_queries}/
                            {search_eval_status.recent_eval.total_queries} queries
                          </span>
                          <span>{search_eval_status.recent_eval.progress_percentage.toFixed(1)}%</span>
                        </div>
                        <div className="w-full bg-secondary rounded-full h-2">
                          <div
                            className="bg-primary h-2 rounded-full transition-all"
                            style={{ width: `${search_eval_status.recent_eval.progress_percentage}%` }}
                          />
                        </div>
                      </div>
                    )}

                    {/* Metrics */}
                    {search_eval_status.recent_eval.status === 'completed' && (
                      <div className="grid grid-cols-2 gap-2 text-xs">
                        <div>
                          <p className="text-muted-foreground">Precision@10</p>
                          <p className="font-bold">{search_eval_status.recent_eval.avg_precision?.toFixed(3)}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Recall@10</p>
                          <p className="font-bold">{search_eval_status.recent_eval.avg_recall?.toFixed(3)}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">MRR</p>
                          <p className="font-bold">{search_eval_status.recent_eval.avg_mrr?.toFixed(3)}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">NDCG@10</p>
                          <p className="font-bold">{search_eval_status.recent_eval.avg_ndcg?.toFixed(3)}</p>
                        </div>
                      </div>
                    )}

                    {/* Error Info */}
                    {search_eval_status.recent_eval.error_message && (
                      <div className="rounded-lg border border-destructive bg-destructive/10 p-2">
                        <p className="text-xs text-destructive">{search_eval_status.recent_eval.error_message}</p>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-sm text-muted-foreground">No eval runs yet</p>
                )}

                {/* Start Eval Button */}
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full"
                  disabled={isStartingSearchEval || search_eval_status.recent_eval?.status === 'running'}
                  onClick={async () => {
                    const evalType = evalTypeToStart;
                    setIsStartingSearchEval(true);
                    try {
                      const response = await fetch('/admin/search_evals', {
                        method: 'POST',
                        headers: {
                          'Content-Type': 'application/json',
                          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                        },
                        body: JSON.stringify({ eval_type: evalType, use_llm_judge: useLLMJudge }),
                      });
                      const data = await response.json();
                      if (response.ok) {
                        window.location.reload();
                      } else {
                        alert(data.error || 'Failed to start eval');
                      }
                    } catch (error) {
                      console.error('Failed to start eval:', error);
                      alert('Failed to start eval');
                    } finally {
                      setIsStartingSearchEval(false);
                    }
                  }}
                >
                  {isStartingSearchEval ? (
                    <>
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                      Starting...
                    </>
                  ) : (
                    <>
                      <CheckCircle className="h-4 w-4 mr-2" />
                      Run Eval (keyword)
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Embedding Generation */}
          <Card>
            <CardHeader>
              <CardTitle>Semantic Search Embeddings</CardTitle>
              <CardDescription>Generate vector embeddings for semantic search</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {/* Embedding Coverage Stats */}
                <div className="space-y-3 p-3 bg-muted/50 rounded-lg">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-muted-foreground">Cards with Embeddings</p>
                      <p className="text-lg font-bold">
                        {embedding_run_status.embedding_coverage.cards_with_embeddings.toLocaleString()}
                        <span className="text-sm font-normal text-muted-foreground">
                          {' '}/ {embedding_run_status.embedding_coverage.total_cards.toLocaleString()}
                        </span>
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Coverage</p>
                      <p className="text-lg font-bold">
                        {embedding_run_status.embedding_coverage.percentage}%
                      </p>
                    </div>
                  </div>
                  {/* Coverage Progress Bar */}
                  <div className="space-y-1">
                    <div className="w-full bg-secondary rounded-full h-2">
                      <div
                        className={`h-2 rounded-full transition-all ${
                          embedding_run_status.embedding_coverage.percentage === 100
                            ? 'bg-green-600'
                            : embedding_run_status.embedding_coverage.percentage > 50
                            ? 'bg-primary'
                            : 'bg-yellow-600'
                        }`}
                        style={{ width: `${embedding_run_status.embedding_coverage.percentage}%` }}
                      />
                    </div>
                  </div>
                </div>

                {embedding_run_status.recent_run ? (
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium">Last Run</p>
                      {getStatusBadge(embedding_run_status.recent_run.status)}
                    </div>

                    {/* Progress Bar */}
                    {embedding_run_status.recent_run.status === 'processing' && (
                      <div className="space-y-1">
                        <div className="flex justify-between text-xs text-muted-foreground">
                          <span>
                            {(embedding_run_status.recent_run.processed_cards ?? 0).toLocaleString()}/
                            {(embedding_run_status.recent_run.total_cards ?? 0).toLocaleString()} cards
                          </span>
                          <span>{(embedding_run_status.recent_run.progress_percentage ?? 0).toFixed(1)}%</span>
                        </div>
                        <div className="w-full bg-secondary rounded-full h-2">
                          <div
                            className="bg-primary h-2 rounded-full transition-all"
                            style={{ width: `${embedding_run_status.recent_run.progress_percentage}%` }}
                          />
                        </div>
                      </div>
                    )}

                    {/* Completed Info */}
                    {embedding_run_status.recent_run.status === 'completed' && (
                      <div className="text-xs text-muted-foreground space-y-1">
                        <p>Completed: {embedding_run_status.recent_run.completed_at}</p>
                        <p>Duration: {embedding_run_status.recent_run.duration_formatted}</p>
                        <p>Cards processed: {(embedding_run_status.recent_run.processed_cards ?? 0).toLocaleString()}</p>
                      </div>
                    )}

                    {/* Error Info */}
                    {embedding_run_status.recent_run.error_message && (
                      <div className="rounded-lg border border-destructive bg-destructive/10 p-2">
                        <p className="text-xs text-destructive">{embedding_run_status.recent_run.error_message}</p>
                      </div>
                    )}

                    {/* Failed Cards Warning */}
                    {embedding_run_status.recent_run.failed_cards > 0 && (
                      <div className="flex items-center gap-2 text-xs text-yellow-600">
                        <AlertCircle className="h-3 w-3" />
                        <span>{embedding_run_status.recent_run.failed_cards} cards failed</span>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-sm text-muted-foreground">No embedding runs yet</p>
                )}

                {/* Start Embedding Button */}
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full"
                  disabled={isStartingEmbeddingRun || embedding_run_status.recent_run?.status === 'processing'}
                  onClick={async () => {
                    setIsStartingEmbeddingRun(true);
                    try {
                      const response = await fetch('/admin/embedding_runs', {
                        method: 'POST',
                        headers: {
                          'Content-Type': 'application/json',
                          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                        },
                      });
                      const data = await response.json();
                      if (response.ok) {
                        window.location.reload();
                      } else {
                        alert(data.error || 'Failed to start embedding generation');
                      }
                    } catch (error) {
                      console.error('Failed to start embedding generation:', error);
                      alert('Failed to start embedding generation');
                    } finally {
                      setIsStartingEmbeddingRun(false);
                    }
                  }}
                >
                  {isStartingEmbeddingRun ? (
                    <>
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                      Starting...
                    </>
                  ) : (
                    <>
                      <Database className="h-4 w-4 mr-2" />
                      Generate Embeddings
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
            <CardDescription>Common administrative tasks and batch operations</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <h4 className="text-sm font-medium mb-2">Sync Operations</h4>
                <div className="flex flex-wrap gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setSyncToStart('oracle_cards')}
                    disabled={!canStartSync(mergedSyncStatus.find(s => s.sync_type === 'oracle_cards'))}
                  >
                    <Download className="h-4 w-4 mr-2" />
                    Sync Oracle Cards
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setSyncToStart('rulings')}
                    disabled={!canStartSync(mergedSyncStatus.find(s => s.sync_type === 'rulings'))}
                  >
                    <Download className="h-4 w-4 mr-2" />
                    Sync Rulings
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setSyncToStart('default_cards')}
                    disabled={!canStartSync(mergedSyncStatus.find(s => s.sync_type === 'default_cards'))}
                  >
                    <Download className="h-4 w-4 mr-2" />
                    Sync Default Cards
                  </Button>
                </div>
              </div>

              <div className="border-t pt-4">
                <h4 className="text-sm font-medium mb-2">System Management</h4>
                <div className="flex gap-2 flex-wrap">
                  <a
                    href="/admin/failures"
                    className="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background bg-destructive text-destructive-foreground hover:bg-destructive/90 h-10 py-2 px-4"
                  >
                    <AlertCircle className="h-4 w-4 mr-2" />
                    View All Failures
                  </a>
                  <a
                    href="/jobs"
                    className="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background bg-primary text-primary-foreground hover:bg-primary/90 h-10 py-2 px-4"
                  >
                    View Background Jobs
                  </a>
                  <button
                    onClick={() => window.location.href = '/rails/info/routes'}
                    className="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background border border-input hover:bg-accent hover:text-accent-foreground h-10 py-2 px-4"
                  >
                    View Routes
                  </button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Confirmation Dialog for Starting Sync */}
      <Dialog open={!!syncToStart} onOpenChange={(open) => !open && setSyncToStart(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Start Sync</DialogTitle>
            <DialogDescription>
              Are you sure you want to start the {syncToStart?.replace(/_/g, ' ')} sync? This will download and process data from Scryfall.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-2 mt-4">
            <Button
              variant="outline"
              onClick={() => setSyncToStart(null)}
            >
              Cancel
            </Button>
            <Button
              onClick={() => syncToStart && startSync(syncToStart)}
              disabled={syncToStart ? isStartingSyncs[syncToStart] : false}
            >
              {syncToStart && isStartingSyncs[syncToStart] ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Starting...
                </>
              ) : (
                <>
                  <Download className="h-4 w-4 mr-2" />
                  Start Sync
                </>
              )}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Sync Details Modal */}
      <Dialog open={!!selectedSync} onOpenChange={(open) => !open && setSelectedSync(null)}>
        <DialogContent className="max-w-3xl max-h-[80vh]">
          <DialogHeader>
            <DialogTitle>
              {syncDetails?.sync.sync_type.replace(/_/g, ' ')} Sync Details
            </DialogTitle>
            <DialogDescription>
              Detailed information about this sync operation
            </DialogDescription>
          </DialogHeader>

          {syncDetails && (
            <div className="h-[60vh] overflow-y-auto pr-4">
              <div className="space-y-4">
                {/* Status and Progress */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm font-medium">Status</p>
                    <div className="flex gap-2 mt-1">
                      {getStatusBadge(syncDetails.sync.status)}
                    </div>
                  </div>
                  <div>
                    <p className="text-sm font-medium">Job Progress</p>
                    <div className="mt-1">
                      <div className="flex gap-2 text-sm">
                        <span className="flex items-center gap-1">
                          <CheckCircle className="h-3 w-3 text-green-600" />
                          {syncDetails.sync.job_progress.completed} completed
                        </span>
                        <span className="flex items-center gap-1">
                          <Clock className="h-3 w-3 text-yellow-600" />
                          {syncDetails.sync.job_progress.pending} pending
                        </span>
                        {syncDetails.sync.job_progress.failed > 0 && (
                          <span className="flex items-center gap-1">
                            <AlertCircle className="h-3 w-3 text-red-600" />
                            {syncDetails.sync.job_progress.failed} failed
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Error Message */}
                {syncDetails.sync.error_message && (
                  <div className="rounded-lg border border-destructive bg-destructive/10 p-3">
                    <div className="flex gap-2">
                      <AlertCircle className="h-4 w-4 text-destructive mt-0.5" />
                      <p className="text-sm text-destructive">{syncDetails.sync.error_message}</p>
                    </div>
                  </div>
                )}

                {/* Failure Logs */}
                {syncDetails.sync.failure_logs && syncDetails.sync.failure_logs.length > 0 && (
                  <div>
                    <div className="flex items-center justify-between mb-3">
                      <h3 className="text-sm font-medium">
                        Failure Logs ({syncDetails.sync.failure_logs.length} total)
                      </h3>
                      <Badge variant="destructive" className="gap-1">
                        <AlertCircle className="h-3 w-3" />
                        {syncDetails.sync.failure_logs.length} failures
                      </Badge>
                    </div>

                    <div className="space-y-2 max-h-96 overflow-y-auto">
                      {syncDetails.sync.failure_logs.map((log, index) => (
                        <div key={index} className="border rounded-lg text-sm">
                          {/* Header */}
                          <div className="bg-muted/50 px-3 py-2 border-b">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <AlertCircle className="h-4 w-4 text-destructive" />
                                <span className="font-medium text-xs">
                                  {log.context?.error_class || 'Error'}
                                </span>
                                {log.batch_number && (
                                  <Badge variant="outline" className="text-xs">
                                    Batch #{log.batch_number}
                                  </Badge>
                                )}
                              </div>
                              <span className="text-xs text-muted-foreground">
                                {formatTime(log.timestamp)}
                              </span>
                            </div>
                          </div>

                          {/* Error Message */}
                          <div className="px-3 py-2">
                            <p className="text-sm text-destructive font-mono break-words">
                              {log.error}
                            </p>
                          </div>

                          {/* Context Details */}
                          {log.context && (
                            <div className="border-t px-3 py-2 bg-muted/30">
                              <div className="space-y-1">
                                {/* Card/Item Details */}
                                {(log.context.card_name || log.context.oracle_id || log.context.card_id) && (
                                  <div className="flex flex-wrap gap-2 mb-2">
                                    {log.context.card_name && (
                                      <div className="flex items-center gap-1">
                                        <span className="text-xs text-muted-foreground">Card:</span>
                                        <span className="text-xs font-medium">{log.context.card_name}</span>
                                      </div>
                                    )}
                                    {log.context.set_code && (
                                      <Badge variant="secondary" className="text-xs">
                                        {log.context.set_code}
                                      </Badge>
                                    )}
                                    {(log.context.oracle_id || log.context.card_id) && (
                                      <code className="text-xs bg-muted px-1 py-0.5 rounded">
                                        {log.context.oracle_id || log.context.card_id}
                                      </code>
                                    )}
                                  </div>
                                )}

                                {/* Backtrace */}
                                {log.context.backtrace && (
                                  <details className="group">
                                    <summary className="cursor-pointer text-xs text-muted-foreground hover:text-foreground">
                                      Stack trace ({log.context.backtrace.length} frames)
                                    </summary>
                                    <div className="mt-1 bg-black/5 dark:bg-white/5 p-2 rounded text-xs">
                                      {log.context.backtrace.map((frame: string, i: number) => (
                                        <div key={i} className="font-mono text-xs leading-relaxed">
                                          {frame.split('/').pop()}
                                        </div>
                                      ))}
                                    </div>
                                  </details>
                                )}

                                {/* Other Context */}
                                {Object.keys(log.context).filter(k =>
                                  !['card_name', 'oracle_id', 'card_id', 'set_code', 'error_class', 'backtrace'].includes(k)
                                ).length > 0 && (
                                  <details className="group">
                                    <summary className="cursor-pointer text-xs text-muted-foreground hover:text-foreground">
                                      Additional context
                                    </summary>
                                    <pre className="mt-1 text-xs bg-black/5 dark:bg-white/5 p-2 rounded overflow-x-auto">
                                      {JSON.stringify(
                                        Object.fromEntries(
                                          Object.entries(log.context).filter(([k]) =>
                                            !['card_name', 'oracle_id', 'card_id', 'set_code', 'error_class', 'backtrace'].includes(k)
                                          )
                                        ),
                                        null,
                                        2
                                      )}
                                    </pre>
                                  </details>
                                )}
                              </div>
                            </div>
                          )}
                        </div>
                      ))}
                    </div>

                    {/* Summary Stats */}
                    {syncDetails.sync.failure_logs.length > 10 && (
                      <div className="mt-3 p-3 bg-muted/50 rounded-lg">
                        <div className="grid grid-cols-2 gap-4 text-xs">
                          <div>
                            <span className="text-muted-foreground">Total Failures:</span>
                            <span className="ml-2 font-medium">{syncDetails.sync.failure_logs.length}</span>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Unique Error Types:</span>
                            <span className="ml-2 font-medium">
                              {new Set(syncDetails.sync.failure_logs.map(l => l.context?.error_class)).size}
                            </span>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </AppLayout>
  );
}