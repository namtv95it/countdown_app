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
    loadGifts();
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
        categoryIds: selectedCats
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
