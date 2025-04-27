// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  connect() {
    console.log("Modal controller connected");
    this.modalTarget.classList.add("hidden");
    this.modalTarget.addEventListener("click", (e) => {
      if (e.target === this.modalTarget) {
        this.close();
      }
    });
    document.addEventListener('keydown', this.handleKeydown.bind(this));
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown.bind(this));
  }

  open(event) {
    const modalId = event.currentTarget.dataset.modalTarget;
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove("hidden");
      document.body.style.overflow = "hidden";
    }
  }

  close(event) {
    const modal = event.currentTarget.closest('[data-modal-target="modal"]');
    if (modal) {
      modal.classList.add('hidden');
      document.body.style.overflow = '';
    }
  }
}
