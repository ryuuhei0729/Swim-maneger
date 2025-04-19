import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "tooltip"]

  connect() {
    // モーダルが表示されているかどうかを追跡
    this.isOpen = false
  }

  open(event) {
    const targetId = event.currentTarget.dataset.modalTarget
    const modal = document.getElementById(targetId)
    if (modal) {
      modal.classList.remove("hidden")
      this.isOpen = true
      document.body.style.overflow = 'hidden'

      // ツールチップを非表示にする
      document.querySelectorAll('.group-hover\\:block').forEach(tooltip => {
        tooltip.style.display = 'none'
      })
    }
  }

  close(event) {
    const modal = event.currentTarget.closest('[data-modal-target="modal"]')
    if (modal) {
      modal.classList.add("hidden")
      this.isOpen = false
      document.body.style.overflow = ''

      // ツールチップの表示を元に戻す
      document.querySelectorAll('.group-hover\\:block').forEach(tooltip => {
        tooltip.style.display = ''
      })
    }
  }

  closeBackground(event) {
    if (event.target === event.currentTarget) {
      const modal = event.currentTarget.closest('[data-modal-target="modal"]')
      if (modal) {
        modal.classList.add("hidden")
        this.isOpen = false
        document.body.style.overflow = ''

        // ツールチップの表示を元に戻す
        document.querySelectorAll('.group-hover\\:block').forEach(tooltip => {
          tooltip.style.display = ''
        })
      }
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // ESCキーでモーダルを閉じる
  keydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      const modal = document.querySelector('[data-modal-target="modal"]:not(.hidden)')
      if (modal) {
        modal.classList.add("hidden")
        this.isOpen = false
        document.body.style.overflow = ''

        // ツールチップの表示を元に戻す
        document.querySelectorAll('.group-hover\\:block').forEach(tooltip => {
          tooltip.style.display = ''
        })
      }
    }
  }
} 