import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["background", "content"]

  connect() {
    console.log("モーダルコントローラー接続成功！")
  }

  open() {
    this.backgroundTarget.classList.remove('hidden')
    this.backgroundTarget.classList.add('flex')
  }

  close() {
    this.backgroundTarget.classList.remove('flex')
    this.backgroundTarget.classList.add('hidden')
  }
}
