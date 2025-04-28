import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  open(event) {
    const modalId = event.currentTarget.dataset.modalId; // ボタンからdata-modal-id取得
    const modal = document.getElementById(modalId); // idでモーダルを探す
    if (modal) {
      modal.classList.remove("hidden");
    }
  }

  close(event) {
    const modal = event.currentTarget.closest(".fixed"); // 一番近いモーダルを探す
    if (modal) {
      modal.classList.add("hidden");
    }
  }
}