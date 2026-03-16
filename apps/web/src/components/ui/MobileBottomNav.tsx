/**
 * MobileBottomNav.tsx
 * 移动端底部导航组件
 * 
 * 功能:
 * - 底部导航栏
 * - 快捷操作按钮
 * - 当前页面高亮
 */

import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, FolderOpen, Share2, Settings,
  Upload, Plus, Menu, X, Trash2, Database,
} from 'lucide-react';
import { cn } from '@/utils';
import { useFileStore } from '@/stores/files';
import { useQuery } from '@tanstack/react-query';
import { filesApi } from '@/services/api';
import { useState } from 'react';

const NAV_ITEMS = [
  { path: '/', label: '概览', icon: LayoutDashboard, exact: true },
  { path: '/files', label: '文件', icon: FolderOpen, exact: false },
  { path: '/shares', label: '分享', icon: Share2, exact: false },
  { path: '/buckets', label: '存储桶', icon: Database, exact: false },
  { path: '/settings', label: '设置', icon: Settings, exact: false },
];

interface MobileBottomNavProps {
  onUpload?: () => void;
  onNewFolder?: () => void;
}

export function MobileBottomNav({ onUpload, onNewFolder }: MobileBottomNavProps) {
  const location = useLocation();
  const [showQuickActions, setShowQuickActions] = useState(false);
  const { selectedFiles } = useFileStore();

  const { data: trashItems = [] } = useQuery({
    queryKey: ['trash'],
    queryFn: () => filesApi.listTrash().then((r) => r.data.data ?? []),
    staleTime: 30000,
  });
  const trashCount = (trashItems as any[]).length;

  const isActive = (item: typeof NAV_ITEMS[0]) =>
    item.exact ? location.pathname === item.path : location.pathname.startsWith(item.path);

  const isInFiles = location.pathname.startsWith('/files');

  return (
    <>
      <nav className="mobile-nav lg:hidden">
        <div className="flex items-center justify-around h-14">
          {NAV_ITEMS.slice(0, 4).map((item) => {
            const Icon = item.icon;
            const active = isActive(item);
            const badge = item.path === '/files' && selectedFiles.length > 0 
              ? selectedFiles.length 
              : null;

            return (
              <NavLink
                key={item.path}
                to={item.path}
                className={cn(
                  'flex flex-col items-center justify-center flex-1 h-full relative',
                  active ? 'text-primary' : 'text-muted-foreground'
                )}
              >
                <div className="relative">
                  <Icon className="h-5 w-5" />
                  {badge && (
                    <span className="absolute -top-1 -right-1 min-w-[16px] h-4 px-1 text-[10px] font-medium bg-primary text-primary-foreground rounded-full flex items-center justify-center">
                      {badge > 99 ? '99+' : badge}
                    </span>
                  )}
                </div>
                <span className="text-[10px] mt-0.5">{item.label}</span>
              </NavLink>
            );
          })}

          <button
            onClick={() => setShowQuickActions(true)}
            className="flex flex-col items-center justify-center flex-1 h-full text-muted-foreground"
          >
            <Menu className="h-5 w-5" />
            <span className="text-[10px] mt-0.5">更多</span>
          </button>
        </div>
      </nav>

      {showQuickActions && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="absolute inset-0 bg-black/50"
            onClick={() => setShowQuickActions(false)}
          />
          <div className="absolute bottom-0 left-0 right-0 bg-card border-t rounded-t-2xl animate-slide-up safe-bottom">
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="font-semibold">快捷操作</h3>
              <button
                onClick={() => setShowQuickActions(false)}
                className="p-1 rounded-full hover:bg-accent"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4 grid grid-cols-4 gap-4">
              {isInFiles && (
                <>
                  <QuickActionButton
                    icon={Upload}
                    label="上传"
                    onClick={() => {
                      setShowQuickActions(false);
                      onUpload?.();
                    }}
                  />
                  <QuickActionButton
                    icon={Plus}
                    label="新建文件夹"
                    onClick={() => {
                      setShowQuickActions(false);
                      onNewFolder?.();
                    }}
                  />
                </>
              )}
              
              <NavLink
                to="/trash"
                onClick={() => setShowQuickActions(false)}
                className="flex flex-col items-center gap-1"
              >
                <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center relative">
                  <Trash2 className="h-5 w-5 text-muted-foreground" />
                  {trashCount > 0 && (
                    <span className="absolute -top-1 -right-1 min-w-[16px] h-4 px-1 text-[10px] font-medium bg-destructive text-destructive-foreground rounded-full flex items-center justify-center">
                      {trashCount > 99 ? '99+' : trashCount}
                    </span>
                  )}
                </div>
                <span className="text-xs text-muted-foreground">回收站</span>
              </NavLink>

              <NavLink
                to="/settings"
                onClick={() => setShowQuickActions(false)}
                className="flex flex-col items-center gap-1"
              >
                <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center">
                  <Settings className="h-5 w-5 text-muted-foreground" />
                </div>
                <span className="text-xs text-muted-foreground">设置</span>
              </NavLink>
            </div>

            <div className="p-4 pt-0">
              <button
                onClick={() => setShowQuickActions(false)}
                className="w-full py-3 text-center text-sm text-muted-foreground bg-muted rounded-lg"
              >
                取消
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

function QuickActionButton({
  icon: Icon,
  label,
  onClick,
}: {
  icon: typeof Upload;
  label: string;
  onClick: () => void;
}) {
  return (
    <button onClick={onClick} className="flex flex-col items-center gap-1">
      <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
        <Icon className="h-5 w-5 text-primary" />
      </div>
      <span className="text-xs text-muted-foreground">{label}</span>
    </button>
  );
}
