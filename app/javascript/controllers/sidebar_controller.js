import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]
  static classes = ["open", "closed"]

  connect() {
    // 初期状態ではサイドバーを閉じる（モバイル時）
    if (window.innerWidth < 768) {
      this.close()
    } else {
      // デスクトップ時は開く
      this.open()
    }
    
    // ハンドラーを一度だけバインドして保存
    this.boundHandleResize = this.handleResize.bind(this)
    this.boundToggle = this.toggle.bind(this)
    
    // ウィンドウリサイズイベントのリスナーを追加
    window.addEventListener('resize', this.boundHandleResize)
    
    // グローバルイベントリスナーを追加
    document.addEventListener('sidebar:toggle', this.boundToggle)
  }

  disconnect() {
    // イベントリスナーをクリーンアップ
    window.removeEventListener('resize', this.boundHandleResize)
    document.removeEventListener('sidebar:toggle', this.boundToggle)
  }

  toggle(event) {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.sidebarTarget.classList.remove(this.closedClass)
    this.sidebarTarget.classList.add(this.openClass)
    // オーバーレイを表示
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove('hidden')
    }
    document.body.style.overflow = 'hidden'
  }

  close() {
    this.sidebarTarget.classList.remove(this.openClass)
    this.sidebarTarget.classList.add(this.closedClass)
    // オーバーレイを非表示
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add('hidden')
    }
    document.body.style.overflow = ''
  }

  isOpen() {
    return this.sidebarTarget.classList.contains(this.openClass)
  }

  // オーバーレイクリックでサイドバーを閉じる
  closeOnOverlayClick() {
    this.close()
  }

  // ウィンドウリサイズ時の処理
  handleResize() {
    if (window.innerWidth >= 768) {
      // デスクトップサイズでは常に開く
      this.sidebarTarget.classList.remove(this.closedClass)
      this.sidebarTarget.classList.add(this.openClass)
      // オーバーレイを非表示
      if (this.hasOverlayTarget) {
        this.overlayTarget.classList.add('hidden')
      }
      document.body.style.overflow = ''
    } else {
      // モバイルサイズでは閉じる
      this.close()
    }
  }
}
