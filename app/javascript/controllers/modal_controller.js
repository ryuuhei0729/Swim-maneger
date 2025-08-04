import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  initialize() {
    // 重複初期化を防ぐためのチェック
    if (this.element.dataset.initialized) {
      return;
    }
    this.element.dataset.initialized = 'true';
    
    // デバッグ情報
    const modalTarget = this.element.dataset.modalTarget;
    const competitionId = this.element.dataset.competitionId;
    if (modalTarget) {
      console.log(`Modal controller initialized for: ${modalTarget} (Competition ID: ${competitionId})`);
    }
  }

  open(event) {
    const modalTarget = event.currentTarget.dataset.modalTarget || event.currentTarget.dataset.modalId;
    const logId = event.currentTarget.dataset.practiceLogId;
    const competitionId = event.currentTarget.dataset.competitionId;
    
    // モーダルターゲットが指定されている場合はそのモーダルを開く
    if (modalTarget) {
      const modal = document.getElementById(modalTarget);
      
      if (modal) {
        modal.classList.remove("hidden");
        
        // エントリー詳細用のfetch
        if (competitionId) {
          const entriesContent = modal.querySelector(`#entriesContent-${competitionId}`);
          
          if (entriesContent) {
            loadEntriesData(competitionId, entriesContent);
          } else {
            // 代替のセレクターを試す
            const alternativeContent = modal.querySelector('#entriesContent');
            if (alternativeContent) {
              loadEntriesData(competitionId, alternativeContent);
            }
          }
        }
      }
    } else {
      // 従来の方法（後方互換性のため）
      const modal = document.getElementById('entriesModal');
      const content = document.getElementById('practice-times-content');
      const entriesContent = document.getElementById('entriesContent');
      
      if (modal) {
        modal.classList.remove("hidden");
        
        // 練習タイム用のfetch
        if (logId && content) {
          fetch(`/practice/practice_times/${logId}`)
            .then(response => response.text())
            .then(html => {
              content.innerHTML = html;
            });
        }
        
        // エントリー詳細用のfetch
        if (competitionId && entriesContent) {
          loadEntriesData(competitionId, entriesContent);
        }
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