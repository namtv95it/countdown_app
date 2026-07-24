// ==========================================
// 1. CẤU HÌNH FIREBASE (BẠN ĐIỀN VÀO ĐÂY)
// ==========================================
const firebaseConfig = {
    apiKey: "AIzaSyC9NBlTH_UStt0Y_Ex9ftwzIOYBj9dJI-I",
    authDomain: "lovin-c69f3.firebaseapp.com",
    projectId: "lovin-c69f3",
    storageBucket: "lovin-c69f3.firebasestorage.app",
    messagingSenderId: "730119079486",
    appId: "1:730119079486:android:4fa00525fde83d392d736f"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// ==========================================
// 2. STATE & DOM ELEMENTS
// ==========================================
let gifts = [];
let specialOccasions = [];
let sortableInstance = null;
let isReordering = false;

// DOM Elements
const lockScreen = document.getElementById('lock-screen');
const dashboardScreen = document.getElementById('dashboard-screen');
const giftModal = document.getElementById('gift-modal');
const giftListEl = document.getElementById('gift-list');
const loadingEl = document.getElementById('loading-indicator');
const emptyStateEl = document.getElementById('empty-state');
const toastEl = document.getElementById('toast');

// Buttons
const btnLogin = document.getElementById('btn-login');
const btnUserMenu = document.getElementById('btn-user-menu');
const dropdownMenu = document.getElementById('user-dropdown-menu');
const menuChangePwd = document.getElementById('menu-change-pwd');
const menuLogout = document.getElementById('menu-logout');
const pwdModal = document.getElementById('pwd-modal');
const btnSavePwd = document.getElementById('btn-save-pwd');
const btnAddNew = document.getElementById('btn-add-new');
const btnSaveGift = document.getElementById('btn-save-gift');
const btnReorder = document.getElementById('btn-reorder');
const btnSaveReorder = document.getElementById('btn-save-reorder');
const btnCancelReorder = document.getElementById('btn-cancel-reorder');
const closeModals = document.querySelectorAll('.close-modal');

// Sidebar DOM
const sidebar = document.getElementById('sidebar');
const sidebarOverlay = document.getElementById('sidebar-overlay');
const btnMobileMenu = document.getElementById('btn-mobile-menu');
const pageTitle = document.getElementById('page-title');

// Sidebar Toggle Logic
if (btnMobileMenu && sidebar && sidebarOverlay) {
    function closeSidebar() {
        sidebar.classList.add('-translate-x-full');
        sidebarOverlay.classList.add('hidden');
    }
    
    btnMobileMenu.addEventListener('click', () => {
        sidebar.classList.remove('-translate-x-full');
        sidebarOverlay.classList.remove('hidden');
    });

    sidebarOverlay.addEventListener('click', closeSidebar);
}

// Checkbox custom styles
const categoryCheckboxes = document.querySelectorAll('#f-categories input[type="checkbox"]');
categoryCheckboxes.forEach(cb => {
    cb.addEventListener('change', (e) => {
        if(e.target.checked) e.target.parentElement.classList.add('checked');
        else e.target.parentElement.classList.remove('checked');
    });
});

// Image preview
document.getElementById('f-imageUrl').addEventListener('input', (e) => {
    const img = document.getElementById('img-preview');
    const placeholder = document.getElementById('img-placeholder');
    if (e.target.value) {
        img.src = e.target.value;
        img.style.display = 'block';
        placeholder.style.display = 'none';
    } else {
        img.src = '';
        img.style.display = 'none';
        placeholder.style.display = 'block';
    }
});

// ==========================================
// 3. AUTHENTICATION (SHA-256 HASHING)
// ==========================================
async function sha256(message) {
    const msgBuffer = new TextEncoder().encode(message);
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

document.getElementById('admin-pwd').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        e.preventDefault();
        btnLogin.click();
    }
});

btnLogin.addEventListener('click', async () => {
    const pwd = document.getElementById('admin-pwd').value;
    const errorEl = document.getElementById('login-error');
    
    if(!pwd) {
        errorEl.textContent = "Vui lòng nhập mật khẩu!";
        errorEl.classList.remove('hidden');
        errorEl.style.display = 'block';
        return;
    }

    btnLogin.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> ĐANG KIỂM TRA...';
    btnLogin.disabled = true;

    try {
        const hash = await sha256(pwd);
        const doc = await db.collection('config').doc('admin').get();
        
        if (doc.exists && doc.data().passwordHash === hash) {
            // Success
            sessionStorage.setItem('isAdmin', 'true');
            errorEl.classList.add('hidden');
            errorEl.style.display = 'none';
            showDashboard();
        } else {
            errorEl.textContent = "Mật khẩu không chính xác!";
            errorEl.classList.remove('hidden');
            errorEl.style.display = 'block';
        }
    } catch (error) {
        errorEl.textContent = "Lỗi kết nối Firebase. Hãy kiểm tra lại Config.";
        errorEl.classList.remove('hidden');
        errorEl.style.display = 'block';
        console.error(error);
    }

    btnLogin.innerHTML = '<span>XÁC NHẬN</span> <i class="fa-solid fa-arrow-right"></i>';
    btnLogin.disabled = false;
});

menuLogout.addEventListener('click', (e) => {
    e.preventDefault();
    dropdownMenu.classList.add('hidden');
    sessionStorage.removeItem('isAdmin');
    dashboardScreen.classList.add('hidden');
    dashboardScreen.classList.remove('flex');
    lockScreen.classList.remove('hidden');
    lockScreen.classList.add('flex');
    document.getElementById('admin-pwd').value = '';
});

// Dropdown logic
btnUserMenu.addEventListener('click', (e) => {
    e.stopPropagation();
    dropdownMenu.classList.toggle('hidden');
});
document.addEventListener('click', () => {
    dropdownMenu.classList.add('hidden');
});
dropdownMenu.addEventListener('click', (e) => e.stopPropagation());

// Change Password logic
menuChangePwd.addEventListener('click', (e) => {
    e.preventDefault();
    dropdownMenu.classList.add('hidden');
    document.getElementById('pwd-form').reset();
    pwdModal.classList.remove('hidden');
    // slight delay for transition
    setTimeout(() => pwdModal.querySelector('.modal-content').classList.replace('scale-95', 'scale-100'), 10);
    setTimeout(() => pwdModal.querySelector('.modal-content').classList.replace('opacity-0', 'opacity-100'), 10);
});

btnSavePwd.addEventListener('click', async () => {
    const form = document.getElementById('pwd-form');
    if (!form.checkValidity()) {
        form.reportValidity();
        return;
    }

    const oldPwd = document.getElementById('f-oldPwd').value;
    const newPwd = document.getElementById('f-newPwd').value;
    const confirmPwd = document.getElementById('f-confirmPwd').value;

    if (newPwd !== confirmPwd) {
        showToast("Mật khẩu mới không khớp!", true);
        return;
    }

    btnSavePwd.textContent = "Đang lưu...";
    btnSavePwd.disabled = true;

    try {
        const oldHash = await sha256(oldPwd);
        const docRef = db.collection('config').doc('admin');
        const doc = await docRef.get();
        
        if (doc.exists && doc.data().passwordHash === oldHash) {
            const newHash = await sha256(newPwd);
            await docRef.update({ passwordHash: newHash });
            showToast("Đổi mật khẩu thành công!");
            pwdModal.querySelector('.modal-content').classList.replace('scale-100', 'scale-95');
            pwdModal.querySelector('.modal-content').classList.replace('opacity-100', 'opacity-0');
            setTimeout(() => pwdModal.classList.add('hidden'), 300);
        } else {
            showToast("Mật khẩu cũ không chính xác!", true);
        }
    } catch (e) {
        showToast("Lỗi kết nối Firebase!", true);
        console.error(e);
    }

    btnSavePwd.textContent = "Lưu Lại";
    btnSavePwd.disabled = false;
});

// Theme Toggling
const btnThemeToggle = document.getElementById('btn-theme-toggle');
if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
  document.documentElement.classList.add('dark');
} else {
  document.documentElement.classList.remove('dark');
}

btnThemeToggle.addEventListener('click', () => {
  if (document.documentElement.classList.contains('dark')) {
    document.documentElement.classList.remove('dark');
    localStorage.theme = 'light';
  } else {
    document.documentElement.classList.add('dark');
    localStorage.theme = 'dark';
  }
});

// Check auth on load
if (sessionStorage.getItem('isAdmin') === 'true') {
    showDashboard();
}

function showDashboard() {
    lockScreen.classList.add('hidden');
    lockScreen.classList.remove('flex');
    dashboardScreen.classList.remove('hidden');
    dashboardScreen.classList.add('flex');
    loadOccasions();
    loadGifts();
}

async function loadOccasions() {
    const occasionsContainer = document.getElementById('f-occasions');
    try {
        const snap = await db.collection('special_occasions').get();
        specialOccasions = [];
        let html = '';
        snap.forEach(doc => {
            const data = doc.data();
            data.id = doc.id;
            specialOccasions.push(data);
            
            html += `
            <label class="category-cb-wrapper flex items-center gap-2 p-3 rounded-xl border border-gray-200 dark:border-white/10 bg-gray-50 dark:bg-white/5 cursor-pointer transition-colors hover:border-primary/50 group occasion-cb-wrapper">
                <input type="checkbox" name="occasions" value="${data.id}" class="hidden peer occasion-cb">
                <div class="w-5 h-5 rounded flex-shrink-0 border-2 border-gray-300 dark:border-gray-500 peer-checked:bg-primary peer-checked:border-primary flex items-center justify-center transition-colors">
                    <i class="fa-solid fa-check text-white text-xs opacity-0 peer-checked:opacity-100"></i>
                </div>
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">${data.emoji} ${data.nameVi}</span>
            </label>`;
        });
        occasionsContainer.innerHTML = html;
        
        // Add event listeners for new occasion checkboxes
        document.querySelectorAll('.occasion-cb').forEach(cb => {
            cb.addEventListener('change', (e) => {
                if(e.target.checked) e.target.parentElement.classList.add('checked');
                else e.target.parentElement.classList.remove('checked');
            });
        });
    } catch (e) {
        console.error(e);
        occasionsContainer.innerHTML = '<span class="text-sm text-red-500">Lỗi tải dữ liệu</span>';
    }
}

// ==========================================
// 4. CRUD OPERATIONS
// ==========================================
function loadGifts() {
    loadingEl.style.display = 'block';
    giftListEl.innerHTML = '';
    emptyStateEl.classList.add('hidden');

    db.collection('gifts').orderBy('order', 'asc').onSnapshot(snapshot => {
        if (isReordering) return; // Don't update list while dragging
        
        gifts = [];
        snapshot.forEach(doc => {
            gifts.push({ id: doc.id, ...doc.data() });
        });
        
        renderGifts();
    }, error => {
        showToast("Lỗi tải dữ liệu", true);
        console.error(error);
    });
}

function renderGifts() {
    loadingEl.style.display = 'none';
    giftListEl.innerHTML = '';
    
    if (gifts.length === 0) {
        emptyStateEl.classList.remove('hidden');
        return;
    }
    emptyStateEl.classList.add('hidden');

    gifts.forEach(gift => {
        const nameVi = gift.name && gift.name.vi ? gift.name.vi : 'Chưa có tên';
        const price = gift.priceRange || '0đ';
        const platformLabel = gift.platform || 'Xem Ngay';
        const badgeText = gift.badge || '';
        
        const card = document.createElement('div');
        // Simulate .glass but adaptive to Light/Dark mode
        card.className = 'gift-card bg-white dark:bg-white/5 border border-gray-200 dark:border-white/10 dark:backdrop-blur-md rounded-2xl overflow-hidden flex flex-col relative shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group';
        card.dataset.id = gift.id;
        
        const imgUrl = gift.imageUrl || '';
        const imageErrorAttr = `onerror="this.src='https://via.placeholder.com/400x400/f3f4f6/9ca3af?text=GIFT'"`
        
        // Define primary color rgb (Pink) for backgrounds
        const primaryColor = '#EC4899';
        const primaryColorRgb = '236, 72, 153';

        card.innerHTML = `
            <!-- Image Hero Section -->
            <div class="h-32 sm:h-40 w-full relative overflow-hidden bg-gray-100 dark:bg-gray-800" style="background-color: rgba(${primaryColorRgb}, 0.05)">
                <img src="${imgUrl}" alt="${nameVi}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" ${imageErrorAttr}>
                
                <!-- Gender Badge -->
                ${gift.gender ? `
                <div class="absolute top-2 left-2 w-6 h-6 bg-black/40 backdrop-blur-sm rounded-full flex items-center justify-center border border-white/20 shadow-sm">
                    <span class="text-xs leading-none" style="margin-top: 1px">${gift.gender === 'male' ? '♂️' : gift.gender === 'female' ? '♀️' : '⚧️'}</span>
                </div>
                ` : ''}

                <!-- Popular Badge -->
                ${badgeText ? `
                <div class="absolute top-2 right-2 px-2 h-5 bg-gradient-to-r from-yellow-500 to-amber-600 rounded-md shadow-lg flex items-center justify-center">
                    <span class="text-[10px] font-bold text-white tracking-wider uppercase leading-none mt-[1px]">${badgeText}</span>
                </div>
                ` : ''}
                
                <!-- Overlay on hover -->
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"></div>
                
                <!-- Order Index Badge (Only in Reordering Mode) -->
                ${isReordering ? `
                <div class="absolute inset-0 bg-black/40 flex items-center justify-center z-20 pointer-events-none">
                    <div class="order-badge w-12 h-12 rounded-full bg-primary text-white flex items-center justify-center text-xl font-black shadow-xl border-2 border-white/20">
                    </div>
                </div>
                ` : ''}
            </div>
            
            <!-- Info Section -->
            <div class="p-3 flex flex-col flex-grow">
                <h3 class="text-sm font-bold text-gray-900 dark:text-white line-clamp-2 mb-3 leading-snug" title="${nameVi}">${nameVi}</h3>
                
                <div class="mt-auto">
                    <div class="text-sm font-black mb-2" style="color: ${primaryColor}">${price}</div>
                    <div class="w-full py-1.5 rounded-lg border flex items-center justify-center gap-1.5 transition-colors mb-3" 
                         style="background-color: rgba(${primaryColorRgb}, 0.1); border-color: rgba(${primaryColorRgb}, 0.3)">
                        <i class="${gift.platform === 'Tiktok Shop' ? 'fa-brands fa-tiktok' : 'fa-solid fa-bag-shopping'} text-[11px]" style="color: ${primaryColor}"></i>
                        <span class="text-xs font-bold" style="color: ${primaryColor}">${platformLabel}</span>
                    </div>
                </div>

                <!-- Admin Actions -->
                <div class="flex gap-2 pt-3 border-t border-gray-100 dark:border-white/10 mt-auto">
                    ${isReordering ? 
                        `<button class="drag-handle flex-1 py-1.5 bg-gray-50 dark:bg-white/5 text-gray-500 dark:text-gray-400 hover:text-primary dark:hover:text-primary rounded-lg cursor-move transition-colors"><i class="fa-solid fa-grip-lines"></i></button>` : 
                        `<button class="flex-1 py-1.5 bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="editGift('${gift.id}')">
                            <i class="fa-solid fa-pen-to-square"></i> Sửa
                         </button>
                         <button class="flex-1 py-1.5 bg-red-50 dark:bg-red-500/10 text-red-500 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="deleteGift('${gift.id}')">
                            <i class="fa-solid fa-trash-can"></i> Xóa
                         </button>`
                    }
                </div>
            </div>
        `;
        giftListEl.appendChild(card);
    });

    initSortable();
}

function initSortable() {
    if (sortableInstance) sortableInstance.destroy();
    
    if (isReordering) {
        sortableInstance = new Sortable(giftListEl, {
            animation: 150,
            handle: '.drag-handle',
            ghostClass: 'sortable-ghost'
        });
    }
}

// Delete
window.deleteGift = async (id) => {
    if(confirm('Bạn có chắc chắn muốn xóa món quà này?')) {
        try {
            await db.collection('gifts').doc(id).delete();
            showToast("Đã xóa quà tặng");
        } catch (e) {
            showToast("Lỗi khi xóa", true);
        }
    }
}

// Bind new gift button in empty state
const emptyStateBtn = document.querySelector('.btn-add-new-trigger');
if(emptyStateBtn) {
    emptyStateBtn.addEventListener('click', () => {
        btnAddNew.click();
    });
}

// Edit (Open Modal)
function editGift(id) {
    const gift = gifts.find(g => g.id === id);
    if (!gift) return;

    document.getElementById('modal-title').innerHTML = '<i class="fa-solid fa-pen text-primary"></i> Sửa Thông Tin Quà';
    document.getElementById('gift-id').value = gift.id;
    
    document.getElementById('f-imageUrl').value = gift.imageUrl || '';
    document.getElementById('f-imageUrl').dispatchEvent(new Event('input'));
    
    document.getElementById('f-nameVi').value = gift.name?.vi || '';
    document.getElementById('f-nameEn').value = gift.name?.en || '';
    document.getElementById('f-price').value = gift.priceRange || '';
    
    document.getElementById('f-badge').value = gift.badge || '';
    document.getElementById('f-platform').value = gift.platform || 'Khác';
    document.getElementById('f-affiliateUrl').value = gift.affiliateUrl || '';
    document.getElementById('f-gender').value = gift.gender || 'unisex';

    // Reset checkboxes
    categoryCheckboxes.forEach(cb => {
        cb.checked = false;
        cb.parentElement.classList.remove('border-primary', 'bg-primary/5');
    });
    
    // Set checkboxes
    const categories = gift.categoryIds || [];
    categoryCheckboxes.forEach(cb => {
        if (categories.includes(cb.value)) {
            cb.checked = true;
            cb.parentElement.classList.add('border-primary', 'bg-primary/5');
        }
    });

    // Set occasion checkboxes
    const occasionCheckboxes = document.querySelectorAll('.occasion-cb');
    occasionCheckboxes.forEach(cb => {
        cb.checked = false;
        cb.parentElement.classList.remove('border-primary', 'bg-primary/5');
    });
    const occasions = gift.occasionIds || [];
    occasionCheckboxes.forEach(cb => {
        if (occasions.includes(cb.value)) {
            cb.checked = true;
            cb.parentElement.classList.add('border-primary', 'bg-primary/5');
        }
    });

    giftModal.classList.remove('hidden');
    setTimeout(() => giftModal.querySelector('.modal-content').classList.replace('scale-95', 'scale-100'), 10);
    setTimeout(() => giftModal.querySelector('.modal-content').classList.replace('opacity-0', 'opacity-100'), 10);
}

// Add New (Open Modal)
btnAddNew.addEventListener('click', () => {
    document.getElementById('gift-form').reset();
    document.getElementById('f-imageUrl').dispatchEvent(new Event('input')); // reset image preview
    document.getElementById('modal-title').textContent = "Thêm Quà Tặng Mới";
    document.getElementById('gift-id').value = '';
    
    // Reset checkboxes visual
    categoryCheckboxes.forEach(cb => cb.parentElement.classList.remove('border-primary', 'bg-primary/5'));
    document.querySelectorAll('.occasion-cb').forEach(cb => cb.parentElement.classList.remove('border-primary', 'bg-primary/5'));
    
    giftModal.classList.remove('hidden');
    setTimeout(() => giftModal.querySelector('.modal-content').classList.replace('scale-95', 'scale-100'), 10);
    setTimeout(() => giftModal.querySelector('.modal-content').classList.replace('opacity-0', 'opacity-100'), 10);
});

// Close Modal logic for tailwind UI
closeModals.forEach(btn => {
    btn.addEventListener('click', () => {
        giftModal.querySelector('.modal-content')?.classList.replace('scale-100', 'scale-95');
        giftModal.querySelector('.modal-content')?.classList.replace('opacity-100', 'opacity-0');
        pwdModal.querySelector('.modal-content')?.classList.replace('scale-100', 'scale-95');
        pwdModal.querySelector('.modal-content')?.classList.replace('opacity-100', 'opacity-0');
        setTimeout(() => {
            giftModal.classList.add('hidden');
            pwdModal.classList.add('hidden');
        }, 300);
    });
});

// Save Gift
btnSaveGift.addEventListener('click', async () => {
    const form = document.getElementById('gift-form');
    if (!form.checkValidity()) {
        form.reportValidity();
        return;
    }

    const id = document.getElementById('gift-id').value;
    
    // Get selected categories
    const selectedCats = [];
    categoryCheckboxes.forEach(cb => {
        if (cb.checked) selectedCats.push(cb.value);
    });

    const selectedOccasions = [];
    document.querySelectorAll('.occasion-cb').forEach(cb => {
        if (cb.checked) selectedOccasions.push(cb.value);
    });

    const giftData = {
        name: {
            vi: document.getElementById('f-nameVi').value,
            en: document.getElementById('f-nameEn').value
        },
        description: { vi: '', en: '' }, // empty description as requested
        imageUrl: document.getElementById('f-imageUrl').value,
        priceRange: document.getElementById('f-price').value,
        badge: document.getElementById('f-badge').value,
        platform: document.getElementById('f-platform').value,
        affiliateUrl: document.getElementById('f-affiliateUrl').value,
        gender: document.getElementById('f-gender').value,
        categoryIds: selectedCats,
        occasionIds: selectedOccasions
    };

    btnSaveGift.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
    btnSaveGift.disabled = true;

    try {
        if (id) {
            // Update
            await db.collection('gifts').doc(id).update(giftData);
            showToast("Đã cập nhật thành công!");
        } else {
            // Add
            giftData.order = Date.now(); // add to end of list
            await db.collection('gifts').add(giftData);
            showToast("Đã thêm quà mới!");
        }
        giftModal.classList.add('hidden');
    } catch (e) {
        showToast("Có lỗi xảy ra khi lưu", true);
        console.error(e);
    }

    btnSaveGift.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Lưu Lại';
    btnSaveGift.disabled = false;
});

// ==========================================
// 5. REORDER LOGIC
// ==========================================
btnReorder.addEventListener('click', () => {
    isReordering = true;
    btnReorder.classList.add('hidden');
    btnAddNew.classList.add('hidden');
    btnSaveReorder.classList.remove('hidden');
    btnCancelReorder.classList.remove('hidden');
    renderGifts();
});

btnCancelReorder.addEventListener('click', () => {
    isReordering = false;
    btnReorder.classList.remove('hidden');
    btnAddNew.classList.remove('hidden');
    btnSaveReorder.classList.add('hidden');
    btnCancelReorder.classList.add('hidden');
    loadGifts(); // reset order
});

btnSaveReorder.addEventListener('click', async () => {
    btnSaveReorder.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
    btnSaveReorder.disabled = true;

    try {
        const batch = db.batch();
        const cards = giftListEl.querySelectorAll('.gift-card');
        
        cards.forEach((card, index) => {
            const id = card.dataset.id;
            const ref = db.collection('gifts').doc(id);
            batch.update(ref, { order: index * 10 });
        });

        await batch.commit();
        showToast("Đã lưu thứ tự hiển thị!");
        
        isReordering = false;
        btnReorder.classList.remove('hidden');
        btnAddNew.classList.remove('hidden');
        btnSaveReorder.classList.add('hidden');
        btnCancelReorder.classList.add('hidden');
        btnSaveReorder.innerHTML = '<i class="fa-solid fa-check"></i> Lưu thứ tự';
        btnSaveReorder.disabled = false;
        
        loadGifts(); // reload to get new orders
    } catch (error) {
        showToast("Lỗi khi lưu thứ tự", true);
        btnSaveReorder.innerHTML = '<i class="fa-solid fa-check"></i> Lưu thứ tự';
        btnSaveReorder.disabled = false;
    }
});

// ==========================================
// 6. UTILS
// ==========================================
function showToast(msg, isError = false) {
    toastEl.innerHTML = isError 
        ? `<i class="fa-solid fa-circle-exclamation"></i> ${msg}`
        : `<i class="fa-solid fa-circle-check"></i> ${msg}`;
    
    if (isError) {
        toastEl.classList.add('bg-red-500', 'text-white');
        toastEl.classList.remove('bg-gray-900', 'dark:bg-white', 'text-white', 'dark:text-gray-900');
    } else {
        toastEl.classList.remove('bg-red-500');
        toastEl.classList.add('bg-gray-900', 'dark:bg-white', 'text-white', 'dark:text-gray-900');
    }
    
    toastEl.classList.replace('translate-y-8', '-translate-y-4');
    toastEl.classList.replace('opacity-0', 'opacity-100');
    
    setTimeout(() => {
        toastEl.classList.replace('-translate-y-4', 'translate-y-8');
        toastEl.classList.replace('opacity-100', 'opacity-0');
    }, 3000);
}

const availableEmojis = [
    '💝', '🎂', '🎉', '🎁', '🎈', '💍', '🥂', '🌹', '🎊', '✨', '🔥', '🏆', '⭐', '🌈', '☀️', '🌸', '🎄', '🎃', '🎆', '🎓'
];

function renderEmojiOptions(selectedEmoji = '') {
    const container = document.getElementById('occ-emoji-options');
    const input = document.getElementById('occ-emoji');
    container.innerHTML = '';
    
    if (!selectedEmoji || !availableEmojis.includes(selectedEmoji)) {
        selectedEmoji = availableEmojis[0];
    }
    input.value = selectedEmoji;

    availableEmojis.forEach(emoji => {
        const btn = document.createElement('div');
        btn.className = `w-10 h-10 rounded-xl cursor-pointer transition-all flex items-center justify-center text-xl select-none`;
        
        if (emoji === selectedEmoji) {
            btn.classList.add('bg-primary', 'text-white', 'shadow-md', 'scale-110');
            btn.innerHTML = `<span style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2))">${emoji}</span>`;
        } else {
            btn.classList.add('bg-gray-100', 'dark:bg-white/5', 'hover:bg-gray-200', 'dark:hover:bg-white/10');
            btn.innerText = emoji;
        }
        
        btn.addEventListener('click', () => {
            input.value = emoji;
            renderEmojiOptions(emoji);
        });
        
        container.appendChild(btn);
    });
}

const availableGradients = [
    'linear-gradient(135deg, #EC4899, #BE185D)',
    'linear-gradient(135deg, #F472B6, #A855F7)',
    'linear-gradient(135deg, #F59E0B, #EF4444)',
    'linear-gradient(135deg, #3B82F6, #06B6D4)',
    'linear-gradient(135deg, #1D4ED8, #3B82F6)',
    'linear-gradient(135deg, #F59E0B, #D97706)',
    'linear-gradient(135deg, #EC4899, #7C3AED)',
    'linear-gradient(135deg, #10B981, #0EA5E9)',
    'linear-gradient(135deg, #EF4444, #16A34A)',
    'linear-gradient(135deg, #7C3AED, #0EA5E9)',
    'linear-gradient(135deg, #7C3AED, #EC4899)',
    'linear-gradient(135deg, #EF4444, #F59E0B)',
    'linear-gradient(135deg, #14B8A6, #06B6D4)',
    'linear-gradient(135deg, #8B5CF6, #3B82F6)',
    'linear-gradient(135deg, #6366F1, #A855F7)',
    'linear-gradient(135deg, #F43F5E, #FB923C)',
    'linear-gradient(135deg, #FBBF24, #F59E0B)',
    'linear-gradient(135deg, #10B981, #34D399)',
    'linear-gradient(135deg, #3B82F6, #93C5FD)',
    'linear-gradient(135deg, #6B7280, #374151)'
];

function renderGradientOptions(selectedGradient = '') {
    const container = document.getElementById('occ-gradient-options');
    const input = document.getElementById('occ-gradient');
    container.innerHTML = '';
    
    // Đảm bảo selectedGradient hợp lệ
    if (!selectedGradient || !availableGradients.includes(selectedGradient)) {
        selectedGradient = availableGradients[0];
    }
    input.value = selectedGradient;

    availableGradients.forEach(grad => {
        const btn = document.createElement('div');
        btn.className = `w-12 h-12 rounded-full cursor-pointer transition-all flex items-center justify-center border-2 shadow-sm hover:scale-110`;
        btn.style.background = grad;
        
        if (grad === selectedGradient) {
            btn.classList.add('border-white', 'shadow-md', 'scale-110');
            btn.innerHTML = '<i class="fa-solid fa-check text-white"></i>';
        } else {
            btn.classList.add('border-transparent');
        }
        
        btn.addEventListener('click', () => {
            input.value = grad;
            renderGradientOptions(grad); // re-render to update UI
        });
        
        container.appendChild(btn);
    });
}

// ==========================================
// 7. TAB NAVIGATION & OCCASIONS CRUD
// ==========================================
const tabGifts = document.getElementById('tab-gifts');
const tabOccasions = document.getElementById('tab-occasions');
const tabStartupBanner = document.getElementById('tab-startup-banner');
const viewGifts = document.getElementById('view-gifts');
const viewOccasions = document.getElementById('view-occasions');
const viewStartupBanner = document.getElementById('view-startup-banner');
const occasionModal = document.getElementById('occasion-modal');
const occasionListContainer = document.getElementById('occasion-list-container');
const occasionEmptyState = document.getElementById('occasion-empty-state');
const btnAddNewOccasion = document.getElementById('btn-add-new-occasion-trigger');
const btnSaveOccasion = document.getElementById('btn-save-occasion');
let isOccasionView = false;

// Tab Switching
if (tabGifts && tabOccasions) {
    tabGifts.addEventListener('click', () => {
        isOccasionView = false;
        
        // Update Title
        if (pageTitle) pageTitle.textContent = "Quản Lý Quà Tặng";
        
        // Update Sidebar active state
        tabGifts.classList.add('bg-primary/10', 'text-primary');
        tabGifts.classList.remove('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        
        if (tabOccasions) {
            tabOccasions.classList.remove('bg-primary/10', 'text-primary');
            tabOccasions.classList.add('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        }
        if (tabStartupBanner) {
            tabStartupBanner.classList.remove('bg-primary/10', 'text-primary');
            tabStartupBanner.classList.add('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        }
        
        viewGifts.classList.remove('hidden');
        if (viewOccasions) viewOccasions.classList.add('hidden');
        if (viewStartupBanner) viewStartupBanner.classList.add('hidden');
        
        // Show/hide correct buttons
        if (btnAddNew) btnAddNew.style.display = 'flex';
        if (btnAddNewOccasion) btnAddNewOccasion.style.display = 'none';
        if (btnReorder) btnReorder.style.display = 'flex'; // Changed to flex for alignment
        
        // Close sidebar on mobile
        if (typeof closeSidebar === 'function') closeSidebar();
    });
    
    tabOccasions.addEventListener('click', () => {
        isOccasionView = true;
        
        // Update Title
        if (pageTitle) pageTitle.textContent = "Quản Lý Sự Kiện";
        
        // Update Sidebar active state
        tabOccasions.classList.add('bg-primary/10', 'text-primary');
        tabOccasions.classList.remove('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        
        if (tabGifts) {
            tabGifts.classList.remove('bg-primary/10', 'text-primary');
            tabGifts.classList.add('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        }
        if (tabStartupBanner) {
            tabStartupBanner.classList.remove('bg-primary/10', 'text-primary');
            tabStartupBanner.classList.add('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        }
        
        if (viewGifts) viewGifts.classList.add('hidden');
        viewOccasions.classList.remove('hidden');
        if (viewStartupBanner) viewStartupBanner.classList.add('hidden');
        
        // Hide gift-specific buttons and show occasion button
        if (btnAddNew) btnAddNew.style.display = 'none';
        if (btnReorder) btnReorder.style.display = 'none';
        if (btnAddNewOccasion) btnAddNewOccasion.style.display = 'flex';
        
        // Close sidebar on mobile
        if (typeof closeSidebar === 'function') closeSidebar();
        
        renderOccasions();
    });
}

function renderOccasions() {
    occasionListContainer.innerHTML = '';
    
    if (specialOccasions.length === 0) {
        occasionEmptyState.classList.remove('hidden');
        return;
    }
    occasionEmptyState.classList.add('hidden');

    specialOccasions.forEach(occ => {
        const card = document.createElement('div');
        card.className = 'bg-white dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-2xl p-5 relative shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col gap-3';
        card.innerHTML = `
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-xl flex items-center justify-center text-2xl shadow-inner" style="background: ${occ.gradient || 'gray'}">
                    ${occ.emoji || '✨'}
                </div>
                <div>
                    <h3 class="text-lg font-bold text-gray-900 dark:text-white">${occ.nameVi}</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">${occ.day} tháng ${occ.month}</p>
                </div>
            </div>
            <div class="mt-auto pt-3 border-t border-gray-100 dark:border-white/10 flex flex-col gap-2">
                <div class="flex gap-2">
                    <button class="flex-1 py-1.5 bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="editOccasion('${occ.id}')">
                        <i class="fa-solid fa-pen-to-square"></i> Sửa
                    </button>
                    <button class="flex-1 py-1.5 bg-red-50 dark:bg-red-500/10 text-red-500 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="deleteOccasion('${occ.id}')">
                        <i class="fa-solid fa-trash-can"></i> Xóa
                    </button>
                </div>
                <button class="w-full py-2.5 bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400 hover:bg-amber-100 dark:hover:bg-amber-500/20 rounded-lg transition-colors font-semibold text-sm flex justify-center items-center gap-2 mt-1" onclick="openAssignProductsModal('${occ.id}')" title="Gán Sản Phẩm">
                    <i class="fa-solid fa-gift"></i> Gán Sản Phẩm
                </button>
            </div>
        `;
        occasionListContainer.appendChild(card);
    });
}

// Add New Occasion Modal
if (btnAddNewOccasion) {
    btnAddNewOccasion.addEventListener('click', () => {
        document.getElementById('occasion-form').reset();
        document.getElementById('modal-title-occasion').innerHTML = '<i class="fa-solid fa-calendar-star text-secondary"></i> <span>Thêm Sự Kiện Mới</span>';
        document.getElementById('occ-id').value = '';
        renderEmojiOptions();
        renderGradientOptions();
        openOccasionModal();
    });
}

// Edit Occasion
window.editOccasion = (id) => {
    const occ = specialOccasions.find(o => o.id === id);
    if (!occ) return;
    
    document.getElementById('modal-title-occasion').innerHTML = '<i class="fa-solid fa-pen text-secondary"></i> <span>Sửa Sự Kiện</span>';
    document.getElementById('occ-id').value = occ.id;
    document.getElementById('occ-nameVi').value = occ.nameVi || '';
    document.getElementById('occ-nameEn').value = occ.nameEn || '';

    renderEmojiOptions(occ.emoji || '');
    document.getElementById('occ-month').value = occ.month || 1;
    document.getElementById('occ-day').value = occ.day || 1;
    renderGradientOptions(occ.gradient || '');
    document.getElementById('occ-categoryId').value = occ.categoryId || 'birthday';
    
    openOccasionModal();
};

// Delete Occasion
window.deleteOccasion = async (id) => {
    if(confirm('Bạn có chắc chắn muốn xóa sự kiện này?')) {
        try {
            await db.collection('special_occasions').doc(id).delete();
            showToast("Đã xóa sự kiện");
            await loadOccasions();
            renderOccasions();
        } catch (e) {
            showToast("Lỗi khi xóa sự kiện", true);
        }
    }
};

function openOccasionModal() {
    occasionModal.classList.remove('hidden');
    setTimeout(() => occasionModal.querySelector('.modal-content').classList.replace('scale-95', 'scale-100'), 10);
    setTimeout(() => occasionModal.querySelector('.modal-content').classList.replace('opacity-0', 'opacity-100'), 10);
}

// Ensure occasionModal is closed by closeModals
closeModals.forEach(btn => {
    btn.addEventListener('click', () => {
        occasionModal?.querySelector('.modal-content')?.classList.replace('scale-100', 'scale-95');
        occasionModal?.querySelector('.modal-content')?.classList.replace('opacity-100', 'opacity-0');
        setTimeout(() => {
            occasionModal?.classList.add('hidden');
        }, 300);
    });
});

// Generate Occasion ID from Vietnamese name
function generateOccasionId(nameVi, day, month) {
    let str = nameVi.toLowerCase();
    str = str.replace(/[àáạảãâầấậẩẫăằắặẳẵ]/g, "a");
    str = str.replace(/[èéẹẻẽêềếệểễ]/g, "e");
    str = str.replace(/[ìíịỉĩ]/g, "i");
    str = str.replace(/[òóọỏõôồốộổỗơờớợởỡ]/g, "o");
    str = str.replace(/[ùúụủũưừứựửữ]/g, "u");
    str = str.replace(/[ỳýỵỷỹ]/g, "y");
    str = str.replace(/đ/g, "d");
    str = str.replace(/[^a-z0-9\s]/g, ""); // remove special chars
    str = str.trim().replace(/\s+/g, "_"); // replace spaces with _
    
    const randomStr = Math.random().toString(36).substring(2, 6);
    return `${str}_${day}${month}_${randomStr}`;
}

// Save Occasion
if (btnSaveOccasion) {
    btnSaveOccasion.addEventListener('click', async () => {
        const form = document.getElementById('occasion-form');
        if (!form.checkValidity()) {
            form.reportValidity();
            return;
        }

        let id = document.getElementById('occ-id').value;
        const occData = {
            nameVi: document.getElementById('occ-nameVi').value,
            nameEn: document.getElementById('occ-nameEn').value,

            emoji: document.getElementById('occ-emoji').value,
            month: parseInt(document.getElementById('occ-month').value) || 1,
            day: parseInt(document.getElementById('occ-day').value) || 1,
            gradient: document.getElementById('occ-gradient').value,
            categoryId: document.getElementById('occ-categoryId').value
        };
        
        if (!id) {
            id = generateOccasionId(occData.nameVi, occData.day, occData.month);
        }

        btnSaveOccasion.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
        btnSaveOccasion.disabled = true;

        try {
            if (document.getElementById('occ-id').value) {
                // Update
                await db.collection('special_occasions').doc(id).update(occData);
                showToast("Đã cập nhật sự kiện!");
            } else {
                // Add with specific ID
                await db.collection('special_occasions').doc(id).set(occData);
                showToast("Đã thêm sự kiện mới!");
            }
            
            occasionModal.classList.add('hidden');
            await loadOccasions();
            renderOccasions();
            
        } catch (e) {
            showToast("Có lỗi xảy ra khi lưu", true);
            console.error(e);
        }

        btnSaveOccasion.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Lưu Lại';
        btnSaveOccasion.disabled = false;
    });
}

// ==========================================
// ASSIGN PRODUCTS TO OCCASION LOGIC
// ==========================================
const assignProductsModal = document.getElementById('assign-products-modal');
const btnSaveAssign = document.getElementById('btn-save-assign');
let initialAssignState = {};

window.openAssignProductsModal = (id) => {
    const occ = specialOccasions.find(o => o.id === id);
    if (!occ) return;

    document.getElementById('assign-modal-title-text').innerText = `Gán SP cho ${occ.nameVi}`;
    document.getElementById('assign-occ-id').value = id;

    const listContainer = document.getElementById('assign-products-list');
    listContainer.innerHTML = '';
    initialAssignState = {};

    if (gifts.length === 0) {
        listContainer.innerHTML = '<p class="text-gray-500">Chưa có sản phẩm nào.</p>';
    } else {
        gifts.forEach(gift => {
            const isSelected = gift.occasionIds && gift.occasionIds.includes(id);
            initialAssignState[gift.id] = isSelected;

            const item = document.createElement('label');
            item.className = `flex items-center justify-between p-3 rounded-xl border ${isSelected ? 'border-primary bg-primary/5' : 'border-gray-200 dark:border-white/10 bg-white dark:bg-white/5'} cursor-pointer transition-colors`;
            item.innerHTML = `
                <div class="flex items-center gap-3">
                    <input type="checkbox" class="w-5 h-5 rounded border-gray-300 text-primary focus:ring-primary" value="${gift.id}" ${isSelected ? 'checked' : ''}>
                    <div>
                        <p class="font-bold text-gray-900 dark:text-white">${gift.name.vi || gift.name.en || 'No Name'}</p>
                        <p class="text-xs text-gray-500">${gift.priceRange}</p>
                    </div>
                </div>
                <img src="${gift.imageUrl}" class="w-10 h-10 rounded-lg object-cover bg-gray-100" onerror="this.src='https://via.placeholder.com/40'">
            `;
            
            // Add click listener to toggle styling
            const checkbox = item.querySelector('input[type="checkbox"]');
            checkbox.addEventListener('change', () => {
                if(checkbox.checked) {
                    item.classList.replace('border-gray-200', 'border-primary');
                    item.classList.replace('dark:border-white/10', 'border-primary');
                    item.classList.replace('bg-white', 'bg-primary/5');
                    item.classList.replace('dark:bg-white/5', 'bg-primary/5');
                } else {
                    item.classList.replace('border-primary', 'border-gray-200');
                    // Need to reset dark mode borders correctly, simplify logic:
                    item.className = `flex items-center justify-between p-3 rounded-xl border ${checkbox.checked ? 'border-primary bg-primary/5' : 'border-gray-200 dark:border-white/10 bg-white dark:bg-white/5'} cursor-pointer transition-colors`;
                }
            });

            listContainer.appendChild(item);
        });
    }

    assignProductsModal.classList.remove('hidden');
    setTimeout(() => assignProductsModal.querySelector('.modal-content').classList.replace('scale-95', 'scale-100'), 10);
    setTimeout(() => assignProductsModal.querySelector('.modal-content').classList.replace('opacity-0', 'opacity-100'), 10);
};

// Close assign modal logic
document.querySelectorAll('#assign-products-modal .btn-close-modal').forEach(btn => {
    btn.addEventListener('click', () => {
        assignProductsModal.querySelector('.modal-content').classList.replace('scale-100', 'scale-95');
        assignProductsModal.querySelector('.modal-content').classList.replace('opacity-100', 'opacity-0');
        setTimeout(() => {
            assignProductsModal.classList.add('hidden');
        }, 300);
    });
});

if (btnSaveAssign) {
    btnSaveAssign.addEventListener('click', async () => {
        const id = document.getElementById('assign-occ-id').value;
        if (!id) return;

        btnSaveAssign.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
        btnSaveAssign.disabled = true;

        try {
            const checkboxes = document.querySelectorAll('#assign-products-list input[type="checkbox"]');
            const batch = db.batch();
            let updatesCount = 0;

            checkboxes.forEach(chk => {
                const giftId = chk.value;
                const wasSelected = initialAssignState[giftId];
                const isSelected = chk.checked;

                if (isSelected && !wasSelected) {
                    // Add
                    const ref = db.collection('gifts').doc(giftId);
                    batch.update(ref, {
                        occasionIds: firebase.firestore.FieldValue.arrayUnion(id)
                    });
                    updatesCount++;
                } else if (!isSelected && wasSelected) {
                    // Remove
                    const ref = db.collection('gifts').doc(giftId);
                    batch.update(ref, {
                        occasionIds: firebase.firestore.FieldValue.arrayRemove(id)
                    });
                    updatesCount++;
                }
            });

            if (updatesCount > 0) {
                await batch.commit();
                showToast("Đã cập nhật sản phẩm thành công!");
                // Reload gifts to update state
                loadGifts();
            }

            document.querySelector('#assign-products-modal .btn-close-modal').click();
        } catch (e) {
            console.error(e);
            showToast("Lỗi khi lưu gán sản phẩm", true);
        }

        btnSaveAssign.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Lưu Lại';
        btnSaveAssign.disabled = false;
    });
}

// ==========================================
// 10. STARTUP BANNER LOGIC
// ==========================================
const btnAddNewSb = document.getElementById('btn-add-new-sb-trigger');
const sbGlobalIsActive = document.getElementById('sb-global-isActive');
const sbEmptyState = document.getElementById('sb-empty-state');
const sbListContainer = document.getElementById('sb-list-container');
const btnAddSbEmpty = document.getElementById('btn-add-sb-empty');
const sbModal = document.getElementById('sb-modal');
const sbForm = document.getElementById('sb-form');
const sbItemId = document.getElementById('sb-item-id');
const sbItemIsActive = document.getElementById('sb-item-isActive');
const sbItemTitle = document.getElementById('sb-item-title');
const sbItemImageUrl = document.getElementById('sb-item-imageUrl');
const sbItemImgPreview = document.getElementById('sb-item-img-preview');
const sbItemImgPlaceholder = document.getElementById('sb-item-img-placeholder');
const btnSaveSbItem = document.getElementById('btn-save-sb-item');

// New action sub-option elements
const sbActionGiftOptions = document.getElementById('sb-action-gift-options');
const sbActionUrlOptions = document.getElementById('sb-action-url-options');
const sbGiftCategoryWrap = document.getElementById('sb-gift-category-wrap');
const sbGiftOccasionWrap = document.getElementById('sb-gift-occasion-wrap');
const sbItemOccasionId = document.getElementById('sb-item-occasionId'); // the grid div
const sbItemActionUrl = document.getElementById('sb-item-actionUrl');

let startupBannerData = { isActive: false, items: [] };
let sbOccasionsLoaded = false;

// Load occasions into sb-item-occasionId select
async function loadSbOccasions() {
    if (sbOccasionsLoaded || !sbItemOccasionId) return;
    try {
        const snap = await db.collection('special_occasions').get();
        let html = '';
        snap.forEach(doc => {
            const d = doc.data();
            html += `
                <label class="flex items-center gap-2 p-2.5 rounded-xl border border-gray-200 dark:border-white/10 cursor-pointer transition-all hover:border-indigo-300 has-[:checked]:border-indigo-500 has-[:checked]:bg-indigo-50 dark:has-[:checked]:bg-indigo-900/30">
                    <input type="radio" name="sb-item-occasionId" value="${doc.id}" class="hidden">
                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300 line-clamp-1">${d.emoji || ''} ${d.nameVi}</span>
                </label>`;
        });
        sbItemOccasionId.innerHTML = html;
        sbOccasionsLoaded = true;
    } catch(e) {
        console.error('Error loading occasions for banner:', e);
    }
}

function updateSbActionSubOptions(actionType) {
    sbActionGiftOptions.classList.toggle('hidden', actionType !== 'gift');
    sbActionUrlOptions.classList.toggle('hidden', actionType !== 'url');
    if (actionType === 'gift') loadSbOccasions();
}

function updateSbGiftDestOptions(dest) {
    sbGiftCategoryWrap.classList.toggle('hidden', dest !== 'category');
    sbGiftOccasionWrap.classList.toggle('hidden', dest !== 'occasion');
}

document.querySelectorAll('input[name="sb-item-actionType"]').forEach(radio => {
    radio.addEventListener('change', () => updateSbActionSubOptions(radio.value));
});

document.querySelectorAll('input[name="sb-gift-dest"]').forEach(radio => {
    radio.addEventListener('change', () => updateSbGiftDestOptions(radio.value));
});


if (tabStartupBanner) {
    tabStartupBanner.addEventListener('click', () => {
        isOccasionView = false;
        if (pageTitle) pageTitle.textContent = "Banner Khởi Động";
        
        tabStartupBanner.classList.add('bg-primary/10', 'text-primary');
        tabStartupBanner.classList.remove('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        
        if (tabGifts) {
            tabGifts.classList.remove('bg-primary/10', 'text-primary');
            tabGifts.classList.add('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        }
        if (tabOccasions) {
            tabOccasions.classList.remove('bg-primary/10', 'text-primary');
            tabOccasions.classList.add('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        }
        
        if (viewGifts) viewGifts.classList.add('hidden');
        if (viewOccasions) viewOccasions.classList.add('hidden');
        viewStartupBanner.classList.remove('hidden');
        
        if (btnAddNew) btnAddNew.style.display = 'none';
        if (btnReorder) btnReorder.style.display = 'none';
        if (btnAddNewOccasion) btnAddNewOccasion.style.display = 'none';
        if (btnAddNewSb) btnAddNewSb.style.display = 'flex';
        
        if (typeof closeSidebar === 'function') closeSidebar();
        
        loadStartupBanner();
    });
}

function loadStartupBanner() {
    db.collection('settings').doc('startup_banner').get().then(doc => {
        if (doc.exists) {
            startupBannerData = doc.data();
            if (!startupBannerData.items) startupBannerData.items = [];
        } else {
            startupBannerData = { isActive: false, items: [] };
        }
        
        if (sbGlobalIsActive) sbGlobalIsActive.checked = startupBannerData.isActive;
        renderStartupBanners();
    }).catch(err => {
        console.error("Error loading startup banner: ", err);
    });
}

function renderStartupBanners() {
    sbListContainer.innerHTML = '';
    
    if (startupBannerData.items.length === 0) {
        sbEmptyState.classList.remove('hidden');
        return;
    }
    sbEmptyState.classList.add('hidden');

    startupBannerData.items.forEach((item, index) => {
        const card = document.createElement('div');
        card.className = 'bg-white dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-2xl overflow-hidden relative shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col group';
        
        // Is Active badge
        const badgeColor = item.isActive ? 'bg-green-500' : 'bg-gray-500';
        const badgeText = item.isActive ? 'Đang bật' : 'Đang tắt';
        
        card.innerHTML = `
            <div class="h-32 w-full relative">
                <img src="${item.imageUrl}" class="w-full h-full object-cover" onerror="this.src=''; this.onerror=null; this.parentElement.innerHTML='<div class=\\'w-full h-full bg-gray-200 dark:bg-gray-800 flex items-center justify-center\\'><i class=\\'fa-regular fa-image text-3xl text-gray-400\\'></i></div>'">
                <div class="absolute top-2 right-2 px-2 py-1 rounded text-[10px] font-bold text-white uppercase tracking-wider ${badgeColor}">${badgeText}</div>
            </div>
            <div class="p-4 flex flex-col flex-1">
                <h3 class="text-lg font-bold text-gray-900 dark:text-white line-clamp-1 mb-1">${item.title || '(Không tiêu đề)'}</h3>
                <p class="text-xs text-gray-500 dark:text-gray-400 mb-4"><i class="fa-solid fa-link mr-1"></i> ${
                    item.actionType === 'gift'
                        ? (item.occasionId ? '🎉 Sự kiện đặc biệt' : '🎁 Trang Quà Tặng' + (item.giftCategoryId ? ` (${item.giftCategoryId})` : ''))
                        : item.actionType === 'url'
                            ? '🌐 Mở link: ' + (item.actionUrl ? item.actionUrl.substring(0, 30) + '...' : '(chưa nhập)')
                            : '❌ Chỉ thông báo'
                }</p>
                <div class="mt-auto flex gap-2 pt-3 border-t border-gray-100 dark:border-white/10">
                    <button class="flex-1 py-1.5 bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="editSbItem('${item.id || index}')">
                        <i class="fa-solid fa-pen-to-square"></i> Sửa
                    </button>
                    <button class="flex-1 py-1.5 bg-red-50 dark:bg-red-500/10 text-red-500 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="deleteSbItem('${item.id || index}')">
                        <i class="fa-solid fa-trash"></i> Xóa
                    </button>
                </div>
            </div>
        `;
        sbListContainer.appendChild(card);
    });
}

function openSbModal(isEdit = false, itemData = null) {
    if (isEdit && itemData) {
        document.getElementById('modal-title-sb').innerHTML = '<i class="fa-solid fa-pen text-primary"></i> <span>Sửa Banner</span>';
        sbItemId.value = itemData.id || '';
        sbItemIsActive.checked = itemData.isActive !== undefined ? itemData.isActive : true;
        sbItemTitle.value = itemData.title || '';
        sbItemImageUrl.value = itemData.imageUrl || '';
        const actionRadio = document.querySelector(`input[name="sb-item-actionType"][value="${itemData.actionType || 'none'}"]`);
        if (actionRadio) actionRadio.checked = true;
        
        // Restore sub-options
        if (sbItemActionUrl) sbItemActionUrl.value = itemData.actionUrl || '';
        
        const giftDest = itemData.occasionId ? 'occasion' : 'category';
        const radioToCheck = document.getElementById(`sb-gift-dest-${giftDest}`);
        if (radioToCheck) radioToCheck.checked = true;
        
        // Wait for occasions to load, then set value
        if (itemData.actionType === 'gift') {
            loadSbOccasions().then(() => {
                const occRadio = document.querySelector(`input[name="sb-item-occasionId"][value="${itemData.occasionId || ''}"]`);
                if (occRadio) occRadio.checked = true;
                const catRadio = document.querySelector(`input[name="sb-item-giftCategoryId"][value="${itemData.giftCategoryId || ''}"]`);
                if (catRadio) catRadio.checked = true;
            });
        } else {
            const catRadio = document.querySelector(`input[name="sb-item-giftCategoryId"][value="${itemData.giftCategoryId || ''}"]`);
            if (catRadio) catRadio.checked = true;
        }

        updateSbActionSubOptions(itemData.actionType || 'none');
        updateSbGiftDestOptions(giftDest);
        
        sbItemImageUrl.dispatchEvent(new Event('input'));
    } else {
        document.getElementById('modal-title-sb').innerHTML = '<i class="fa-solid fa-bullhorn text-primary"></i> <span>Thêm Banner Mới</span>';
        sbForm.reset();
        sbItemId.value = '';
        sbItemIsActive.checked = true;
        sbItemImgPreview.src = '';
        sbItemImgPreview.classList.add('hidden');
        sbItemImgPlaceholder.classList.remove('hidden');
        // Reset sub-options
        updateSbActionSubOptions('none');
        const radioCategory = document.getElementById('sb-gift-dest-category');
        if (radioCategory) radioCategory.checked = true;
        updateSbGiftDestOptions('category');
    }
    
    sbModal.classList.remove('hidden');
    setTimeout(() => {
        sbModal.querySelector('.modal-content').classList.remove('scale-95', 'opacity-0');
    }, 10);
}

function closeSbModalFunc() {
    const content = sbModal.querySelector('.modal-content');
    content.classList.add('scale-95', 'opacity-0');
    setTimeout(() => {
        sbModal.classList.add('hidden');
        sbForm.reset();
    }, 300);
}

if (sbModal) {
    sbModal.querySelectorAll('.close-modal').forEach(btn => {
        btn.addEventListener('click', closeSbModalFunc);
    });
}

window.editSbItem = function(id) {
    const item = startupBannerData.items.find((x, idx) => (x.id === id) || (idx.toString() === id.toString()));
    if (item) openSbModal(true, { ...item, id });
}

window.deleteSbItem = function(id) {
    if (confirm('Bạn có chắc chắn muốn xóa banner này?')) {
        startupBannerData.items = startupBannerData.items.filter((x, idx) => (x.id !== id) && (idx.toString() !== id.toString()));
        saveStartupBannerData();
    }
}

if (sbItemImageUrl) {
    sbItemImageUrl.addEventListener('input', () => {
        if (sbItemImageUrl.value) {
            sbItemImgPreview.src = sbItemImageUrl.value;
            sbItemImgPreview.classList.remove('hidden');
            sbItemImgPlaceholder.classList.add('hidden');
        } else {
            sbItemImgPreview.src = '';
            sbItemImgPreview.classList.add('hidden');
            sbItemImgPlaceholder.classList.remove('hidden');
        }
    });
}

if (sbGlobalIsActive) {
    sbGlobalIsActive.addEventListener('change', () => {
        startupBannerData.isActive = sbGlobalIsActive.checked;
        saveStartupBannerData(false); // don't show toast for global toggle to be quick
    });
}

if (btnAddSbEmpty) btnAddSbEmpty.addEventListener('click', () => openSbModal(false));
if (btnAddNewSb) btnAddNewSb.addEventListener('click', () => openSbModal(false));

if (btnSaveSbItem) {
    btnSaveSbItem.addEventListener('click', (e) => {
        if (sbForm && !sbForm.reportValidity()) {
            return;
        }
        
        const id = sbItemId.value;
        const selectedAction = document.querySelector('input[name="sb-item-actionType"]:checked');
        const actionType = selectedAction ? selectedAction.value : 'none';
        
        // Build extra action data based on type
        const selectedGiftDest = document.querySelector('input[name="sb-gift-dest"]:checked');
        const giftDest = selectedGiftDest ? selectedGiftDest.value : 'category';
        
        const selectedCat = document.querySelector('input[name="sb-item-giftCategoryId"]:checked');
        const catVal = selectedCat ? selectedCat.value : '';
        const selectedOcc = document.querySelector('input[name="sb-item-occasionId"]:checked');
        const occVal = selectedOcc ? selectedOcc.value : '';
        
        const data = {
            id: id || Date.now().toString(),
            isActive: sbItemIsActive ? sbItemIsActive.checked : true,
            title: sbItemTitle ? sbItemTitle.value.trim() : '',
            imageUrl: sbItemImageUrl ? sbItemImageUrl.value.trim() : '',
            actionType: actionType,
            // Clear all sub-fields first, then fill based on type
            actionUrl: actionType === 'url' ? (sbItemActionUrl ? sbItemActionUrl.value.trim() : '') : null,
            giftCategoryId: (actionType === 'gift' && giftDest === 'category') ? catVal : null,
            occasionId: (actionType === 'gift' && giftDest === 'occasion') ? occVal : null,
        };
        
        if (id) {
            const index = startupBannerData.items.findIndex((x, idx) => (x.id === id) || (idx.toString() === id.toString()));
            if (index !== -1) startupBannerData.items[index] = data;
        } else {
            startupBannerData.items.push(data);
        }
        
        btnSaveSbItem.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
        btnSaveSbItem.disabled = true;
        
        saveStartupBannerData(true).finally(() => {
            btnSaveSbItem.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> <span>Lưu Lại</span>';
            btnSaveSbItem.disabled = false;
            closeSbModalFunc();
        });
    });
}

function saveStartupBannerData(showToastMsg = true) {
    return db.collection('settings').doc('startup_banner').set(startupBannerData, { merge: true }).then(() => {
        if (showToastMsg) showToast("Lưu cấu hình Banner thành công!");
        renderStartupBanners();
    }).catch(err => {
        console.error(err);
        if (showToastMsg) showToast("Lỗi khi lưu Banner", true);
    });
}

