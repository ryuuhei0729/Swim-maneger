import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  open(event) {
    const modalTarget = event.currentTarget.dataset.modalTarget || event.currentTarget.dataset.modalId;
    const logId = event.currentTarget.dataset.practiceLogId;
    const modal = document.getElementById(modalTarget);
    const content = document.getElementById('practice-times-content');
    if (modal) {
      modal.classList.remove("hidden");
      // 練習タイム用のfetchのみ、logIdとcontentが存在する場合のみ実行
      if (logId && content) {
        fetch(`/practice/practice_times/${logId}`)
          .then(response => response.text())
          .then(html => {
            content.innerHTML = html;
          });
      }
    }
  }

  close(event) {
    const modal = event.currentTarget.closest(".fixed");
    if (modal) {
      modal.classList.add("hidden");
    }
  }
}