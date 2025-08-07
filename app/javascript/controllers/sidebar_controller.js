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
    
    // ウィンドウリサイズイベントのリスナーを追加
    window.addEventListener('resize', this.handleResize.bind(this))
    
    // グローバルイベントリスナーを追加
    document.addEventListener('sidebar:toggle', this.toggle.bind(this))
  }

  disconnect() {
    // イベントリスナーをクリーンアップ
    window.removeEventListener('resize', this.handleResize.bind(this))
    document.removeEventListener('sidebar:toggle', this.toggle.bind(this))
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
