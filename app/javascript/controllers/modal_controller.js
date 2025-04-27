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
  }

  open() {
    console.log("Opening modal");
    this.modalTarget.classList.remove("hidden");
    document.body.style.overflow = "hidden";
  }

  close() {
    console.log("Closing modal");
    this.modalTarget.classList.add("hidden");
    document.body.style.overflow = "";
  }
}
