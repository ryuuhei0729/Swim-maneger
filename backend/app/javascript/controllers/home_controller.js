import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "tabContent", "sortHeader"]
  static values = { defaultTab: String }

  connect() {
    // バウンドされたハンドラーを作成（一度だけ）
    this.boundHandleTabClick = this.handleTabClick.bind(this)
    this.boundHandleSortClick = this.handleSortClick.bind(this)
    
    this.initializeTabs()
    this.initializeSortHeaders()
  }

  disconnect() {
    // イベントリスナーをクリーンアップ
    this.tabTargets.forEach((tab) => {
      tab.removeEventListener('click', this.boundHandleTabClick)
    })
    
    this.sortHeaderTargets.forEach((header) => {
      header.removeEventListener('click', this.boundHandleSortClick)
    })
  }

  initializeTabs() {
    this.tabTargets.forEach((tab, index) => {
      // 既存のイベントリスナーを削除
      tab.removeEventListener('click', this.boundHandleTabClick)
      
      // 新しいイベントリスナーを追加
      tab.addEventListener('click', this.boundHandleTabClick)
    })
  }

  initializeSortHeaders() {
    this.sortHeaderTargets.forEach((header, index) => {
      // 既存のイベントリスナーを削除
      header.removeEventListener('click', this.boundHandleSortClick)
      
      // 新しいイベントリスナーを追加
      header.addEventListener('click', this.boundHandleSortClick)
    })
  }

  handleTabClick(e) {
    e.preventDefault()
    e.stopPropagation()
    this.switchTab(e.target)
  }

  handleSortClick(e) {
    e.preventDefault()
    e.stopPropagation()
    this.handleSort(e.target)
  }

  switchTab(clickedTab) {
    const targetId = clickedTab.dataset.tabsTarget
    const target = document.querySelector(targetId)
    const tabId = clickedTab.id.replace('-tab', '')
    
    if (!target) {
      return
    }
    
    // Hide all tab contents
    this.tabContentTargets.forEach(content => {
      content.classList.add('hidden')
    })
    
    // Show the selected tab content
    target.classList.remove('hidden')
    
    // Update tab styles
    this.tabTargets.forEach(tab => {
      tab.classList.remove('border-blue-600', 'text-blue-600', 'bg-blue-100')
      tab.classList.add('border-transparent', 'hover:text-gray-600', 'hover:border-gray-300')
    })
    
    clickedTab.classList.remove('border-transparent', 'hover:text-gray-600', 'hover:border-gray-300')
    clickedTab.classList.add('border-blue-600', 'text-blue-600', 'bg-blue-100')

    // URLパラメータを更新
    this.updateUrlParameter('tab', tabId)
  }

  handleSort(clickedHeader) {
    const sortBy = clickedHeader.dataset.sortBy
    const currentSortBy = new URLSearchParams(window.location.search).get('sort_by')
    const currentTab = new URLSearchParams(window.location.search).get('tab') || this.defaultTabValue
    
    // URLパラメータを更新
    if (currentSortBy === sortBy) {
      // 同じヘッダーを再度クリックした場合は並び替えを解除
      this.removeUrlParameter('sort_by')
    } else {
      // 新しいヘッダーをクリックした場合は並び替えを適用
      this.updateUrlParameter('sort_by', sortBy)
    }

    // 現在のタブを保持
    this.updateUrlParameter('tab', currentTab)
    
    // ページをリロード
    window.location.reload()
  }

  updateUrlParameter(key, value) {
    const url = new URL(window.location.href)
    url.searchParams.set(key, value)
    window.history.pushState({}, '', url)
  }

  removeUrlParameter(key) {
    const url = new URL(window.location.href)
    url.searchParams.delete(key)
    window.history.pushState({}, '', url)
  }
}
