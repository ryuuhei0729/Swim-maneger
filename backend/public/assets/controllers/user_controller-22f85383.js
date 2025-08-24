import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  showModal(event) {
    const userCard = event.currentTarget
    const userData = {
      id: userCard.dataset.userId,
      name: userCard.dataset.userName,
      generation: userCard.dataset.userGeneration,
      birthday: userCard.dataset.userBirthday,
      bio: userCard.dataset.userBio,
      avatar: userCard.dataset.userAvatar
    }

    // モーダルのタイトルを更新
    const modalTitle = document.querySelector(`#user-modal h3`)
    if (modalTitle) {
      modalTitle.textContent = `${userData.name}の詳細情報`
    }

    // モーダルの内容を更新
    const modalContent = document.getElementById('user-modal-content')
    if (modalContent) {
      modalContent.innerHTML = `
        <div class="flex items-center space-x-6 mb-6">
          <div class="flex-shrink-0">
            ${userData.avatar ? 
              `<img src="${userData.avatar}" alt="${userData.name}のプロフィール画像" class="w-24 h-24 rounded-full">` :
              `<div class="w-24 h-24 rounded-full bg-blue-800 flex items-center justify-center">
                <span class="text-white text-3xl">${userData.name[0]}</span>
              </div>`
            }
          </div>
          <div class="flex-1">
            <h2 class="text-2xl font-bold text-gray-900">${userData.name}</h2>
            <p class="text-gray-500">${userData.generation}期生</p>
            <p class="text-gray-500">${userData.birthday}</p>
          </div>
        </div>
        
        <div class="mt-4 border-t border-gray-200 pt-4">
          <h3 class="text-lg font-semibold text-gray-900 mb-2">自己紹介</h3>
          ${userData.bio ? 
            `<p class="text-gray-700 whitespace-pre-wrap">${userData.bio}</p>` :
            `<p class="text-gray-500 italic">自己紹介が設定されていません</p>`
          }
        </div>
      `
    }

    // モーダルを表示
    const modal = document.getElementById('user-modal')
    if (modal) {
      modal.classList.remove('hidden')
    }
  }
} 