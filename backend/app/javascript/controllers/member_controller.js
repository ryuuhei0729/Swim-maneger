import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupMemberTypeButtons()
    this.setupGenerationButtons()
  }

  setupMemberTypeButtons() {
    document.querySelectorAll('.member-type-button').forEach(button => {
      button.addEventListener('click', () => {
        this.showMembers(button.dataset.type)
      })
    })
  }

  setupGenerationButtons() {
    document.querySelectorAll('.generation-button').forEach(button => {
      button.addEventListener('click', () => {
        this.showMembers('player', button.dataset.generation)
      })
    })
  }

  showMembers(type, generation = null) {
    // アクティブ状態のリセット
    document.querySelectorAll('.member-type-button, .generation-button').forEach(btn => {
      btn.classList.remove('active')
    })

    // クリックされたボタンをアクティブに
    if (generation) {
      document.querySelector(`.generation-button[data-generation="${generation}"]`).classList.add('active')
    } else {
      document.querySelector(`.member-type-button[data-type="${type}"]`).classList.add('active')
    }

    // すべてのメンバーを一旦非表示
    document.querySelectorAll('.member-list > div > .grid > div').forEach(card => {
      card.classList.add('hidden')
    })

    // 条件に合うメンバーを表示
    const cards = document.querySelectorAll(`.member-list[data-type="${type}"] > div > .grid > div`)
    cards.forEach(card => {
      if (generation) {
        const cardGeneration = card.querySelector('.text-sm.text-gray-600 p').textContent.match(/(\d+)期/)[1]
        if (cardGeneration === generation) {
          card.classList.remove('hidden')
        }
      } else {
        card.classList.remove('hidden')
      }
    })

    // リストの表示切り替え
    document.querySelectorAll('.member-list').forEach(list => {
      list.classList.toggle('hidden', list.dataset.type !== type)
    })
  }
} 