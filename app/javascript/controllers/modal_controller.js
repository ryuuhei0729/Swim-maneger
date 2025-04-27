// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  //一旦「モーダル外クリック閉じる」は諦めるか
  // connect() {
  //   this.modalTarget.classList.add("hidden");
  //   this.modalTarget.addEventListener("click", (e) => {
  //     if (e.target === this.modalTarget) {
  //       this.close();
  //     }
  //   });
  // }

  open() {
    this.modalTarget.classList.remove("hidden");
  }

  close() {
    this.modalTarget.classList.add("hidden");
  }
}
