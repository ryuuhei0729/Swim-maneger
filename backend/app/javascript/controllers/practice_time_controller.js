import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  openTableModal(event) {
    event.preventDefault()
    const laps = document.getElementById('laps').value
    const sets = document.getElementById('sets').value
    
    if (!laps || !sets) {
      alert('本数とセット数を入力してください。')
      return
    }

    // フォームを送信してページをリロード
    const form = event.target.closest('form')
    form.action = window.location.href
    form.method = 'get'
    form.submit()
  }
} 