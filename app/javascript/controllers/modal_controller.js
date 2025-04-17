import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

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
    }
  }

  close(event) {
    const modal = event.currentTarget.closest('[data-modal-target="modal"]')
    if (modal) {
      modal.classList.add("hidden")
      this.isOpen = false
    }
  }

  // ESCキーでモーダルを閉じる
  keydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      const modal = document.querySelector('[data-modal-target="modal"]:not(.hidden)')
      if (modal) {
        modal.classList.add("hidden")
        this.isOpen = false
      }
    }
  }
} 