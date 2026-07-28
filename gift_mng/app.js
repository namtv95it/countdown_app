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
const btnDeployVersion = document.getElementById('btn-deploy-version');
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
// 3. AUTHENTICATION & USER MANAGEMENT
// ==========================================
const DEFAULT_SUPER_ADMIN_UID = 'dKth5JKXdKg9SLEoyCSDTMsqYrr2';

const EFFECT_NAMES_VI = {
    'hearts': 'Trái tim',
    'bubbles': 'Bóng bóng',
    'snow': 'Tuyết rơi',
    'stars': 'Sao đêm',
    'meteor': 'Sao băng',
    'rain': 'Mưa rơi',
    'rain_ripple': 'Gợn sóng mưa',
    'rainbow': 'Cầu vồng',
    'waves': 'Sóng biển',
    'leaves': 'Lá rơi',
    'sunset_birds': 'Chim hoàng hôn',
    'aurora': 'Cực quang',
    'fireflies': 'Đom đốm',
    'fireworks': 'Pháo hoa',
    'cherry_blossom': 'Hoa đào',
    'galaxy': 'Thiên hà'
};

let allUsersData = [];
let currentUserFilter = 'all';
let currentSearchQuery = '';
let currentUserRole = 'user';
let isSuperAdmin = false;
let isAdmin = false;
let isManager = false;
let userListenerUnsubscribe = null;
let selectedUserForModal = null;

// Google Sign-In Provider
const googleProvider = new firebase.auth.GoogleAuthProvider();
const btnLoginGoogle = document.getElementById('btn-login-google');

if (btnLoginGoogle) {
    btnLoginGoogle.addEventListener('click', async () => {
        const errorEl = document.getElementById('login-error');
        btnLoginGoogle.innerHTML = '<i class="fa-solid fa-spinner fa-spin text-lg"></i> <span>ĐANG ĐĂNG NHẬP...</span>';
        btnLoginGoogle.disabled = true;

        try {
            await firebase.auth().signInWithPopup(googleProvider);
            if (errorEl) {
                errorEl.classList.add('hidden');
                errorEl.style.display = 'none';
            }
        } catch (error) {
            if (errorEl) {
                if (error.code === 'auth/unauthorized-domain' || (error.message && error.message.includes('unauthorized-domain'))) {
                    const currentDomain = window.location.hostname || 'localhost';
                    errorEl.innerHTML = `
                        <div class="text-left bg-red-500/10 border border-red-500/30 p-3.5 rounded-xl text-xs text-red-400 space-y-2 mt-4">
                            <p class="font-bold flex items-center gap-1.5 text-sm text-red-400">
                                <i class="fa-solid fa-triangle-exclamation text-amber-400"></i> Tên miền chưa được thêm vào Firebase Console
                            </p>
                            <p>Tên miền bạn đang mở (<b>${currentDomain}</b>) chưa có trong danh sách Authorized Domains của Firebase.</p>
                            <p class="font-semibold text-gray-200">👉 Hướng dẫn khắc phục (Chỉ cần 1 phút):</p>
                            <ol class="list-decimal list-inside space-y-1 text-[11px] text-gray-300">
                                <li>Vào <a href="https://console.firebase.google.com/" target="_blank" class="underline text-blue-400 font-bold">Firebase Console</a> ➔ Chọn dự án <b>lovin-c69f3</b></li>
                                <li>Chọn tab <b>Authentication</b> ➔ <b>Settings</b> ➔ <b>Authorized domains</b></li>
                                <li>Bấm <b>Add domain</b> ➔ Nhập <code>${currentDomain}</code> (hoặc <code>localhost</code>) và Lưu.</li>
                            </ol>
                        </div>`;
                } else {
                    errorEl.textContent = "Lỗi đăng nhập Google: " + (error.message || "Vui lòng thử lại");
                }
                errorEl.classList.remove('hidden');
                errorEl.style.display = 'block';
            }
            console.error(error);
        }

        btnLoginGoogle.innerHTML = `
            <svg class="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
            </svg>
            <span>ĐĂNG NHẬP VỚI GOOGLE</span>`;
        btnLoginGoogle.disabled = false;
    });
}

menuLogout.addEventListener('click', (e) => {
    e.preventDefault();
    dropdownMenu.classList.add('hidden');
    if (userListenerUnsubscribe) userListenerUnsubscribe();
    firebase.auth().signOut().catch(err => {
        showToast("Lỗi khi đăng xuất", true);
    });
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

// Auth state observer
firebase.auth().onAuthStateChanged(async (user) => {
    if (user) {
        try {
            // Read role from Firestore users/{uid}
            const userDoc = await db.collection('users').doc(user.uid).get();
            let role = userDoc.exists ? (userDoc.data().role || 'user') : 'user';

            if (user.uid === DEFAULT_SUPER_ADMIN_UID) {
                role = 'super_admin';
            }

            currentUserRole = role;
            isSuperAdmin = role === 'super_admin';
            isAdmin = role === 'admin' || isSuperAdmin;
            isManager = role === 'manager';

            if (!isSuperAdmin && !isAdmin && !isManager) {
                const errorEl = document.getElementById('login-error');
                if (errorEl) {
                    errorEl.textContent = "Tài khoản Google không có quyền truy cập hệ thống Quản trị!";
                    errorEl.classList.remove('hidden');
                    errorEl.style.display = 'block';
                }
                await firebase.auth().signOut();
                hideDashboard();
                return;
            }

            // Update Header User Profile UI
            const nameEl = document.getElementById('user-display-name');
            const emailEl = document.getElementById('user-email-text');
            const avatarEl = document.getElementById('user-avatar-img');
            const roleBadgeEl = document.getElementById('user-role-badge');

            if (nameEl) nameEl.textContent = user.displayName || user.email || 'Admin';
            if (emailEl) emailEl.textContent = user.email || 'Google User';
            if (avatarEl && user.photoURL) avatarEl.src = user.photoURL;

            if (roleBadgeEl) {
                if (isSuperAdmin) {
                    roleBadgeEl.textContent = '👑 Super Admin';
                    roleBadgeEl.className = 'inline-block mt-1 px-2 py-0.5 text-[10px] font-bold rounded bg-purple-500/20 text-purple-400 border border-purple-500/30';
                } else if (role === 'admin') {
                    roleBadgeEl.textContent = '🛡️ Admin';
                    roleBadgeEl.className = 'inline-block mt-1 px-2 py-0.5 text-[10px] font-bold rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30';
                } else if (role === 'manager') {
                    roleBadgeEl.textContent = '👔 Manager';
                    roleBadgeEl.className = 'inline-block mt-1 px-2 py-0.5 text-[10px] font-bold rounded bg-blue-500/20 text-blue-400 border border-blue-500/30';
                }
            }

            showDashboard();
        } catch (e) {
            console.error("Auth role check error:", e);
            await firebase.auth().signOut();
            hideDashboard();
        }
    } else {
        hideDashboard();
    }
});

function showDashboard() {
    lockScreen.classList.add('hidden');
    lockScreen.classList.remove('flex');
    dashboardScreen.classList.remove('hidden');
    dashboardScreen.classList.add('flex');

    const tabGifts = document.getElementById('tab-gifts');
    const tabOccasions = document.getElementById('tab-occasions');
    const tabCategories = document.getElementById('tab-categories');
    const tabStartupBanner = document.getElementById('tab-startup-banner');
    const tabPromoCodes = document.getElementById('tab-promo-codes');
    const tabUsers = document.getElementById('tab-users');
    const chipFilterAnon = document.getElementById('chip-filter-anon');

    if (isManager) {
        // Manager role: hide content editing tabs, show only User Management
        if (tabGifts) tabGifts.style.display = 'none';
        if (tabOccasions) tabOccasions.style.display = 'none';
        if (tabCategories) tabCategories.style.display = 'none';
        if (tabStartupBanner) tabStartupBanner.style.display = 'none';
        if (tabPromoCodes) tabPromoCodes.style.display = 'none';
        if (chipFilterAnon) chipFilterAnon.style.display = 'none';

        // Auto activate Users tab
        if (tabUsers) tabUsers.click();
    } else {
        if (tabGifts) tabGifts.style.display = 'flex';
        if (tabOccasions) tabOccasions.style.display = 'flex';
        if (tabCategories) tabCategories.style.display = 'flex';
        if (tabStartupBanner) tabStartupBanner.style.display = 'flex';
        if (tabPromoCodes) tabPromoCodes.style.display = 'flex';
        if (chipFilterAnon) chipFilterAnon.style.display = 'inline-block';

        loadOccasions();
        loadGifts();
        loadCategories();
    }

    loadUsersData();
}

function hideDashboard() {
    dashboardScreen.classList.add('hidden');
    dashboardScreen.classList.remove('flex');
    lockScreen.classList.remove('hidden');
    lockScreen.classList.add('flex');
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
                if (e.target.checked) e.target.parentElement.classList.add('checked');
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

function renderGiftCategoryFilter() {
    const filterSelect = document.getElementById('gift-filter-category');
    if (!filterSelect) return;

    const currentVal = filterSelect.value;
    let html = '<option value="">🎁 Tất cả danh mục gợi ý</option>';

    categories.forEach(cat => {
        if (cat.isActive === false || !cat.canSuggestProducts) return;
        html += `<option value="${cat.id}">${cat.emoji || '🎁'} ${cat.name}</option>`;
    });

    filterSelect.innerHTML = html;
    if (currentVal) filterSelect.value = currentVal;
}

function renderGifts() {
    loadingEl.style.display = 'none';
    giftListEl.innerHTML = '';

    const searchInput = document.getElementById('gift-search-input');
    const filterCategory = document.getElementById('gift-filter-category');

    const searchVal = (searchInput ? searchInput.value : '').toLowerCase().trim();
    const catVal = filterCategory ? filterCategory.value : '';

    const filteredGifts = gifts.filter(gift => {
        if (catVal && (!gift.categoryIds || !gift.categoryIds.includes(catVal))) {
            return false;
        }
        if (searchVal) {
            const nameVi = (gift.name && gift.name.vi ? gift.name.vi : '').toLowerCase();
            const nameEn = (gift.name && gift.name.en ? gift.name.en : '').toLowerCase();
            if (!nameVi.includes(searchVal) && !nameEn.includes(searchVal)) {
                return false;
            }
        }
        return true;
    });

    const countTextEl = document.getElementById('gift-count-text');
    if (countTextEl) {
        if (filteredGifts.length === gifts.length) {
            countTextEl.textContent = `Tổng số: ${gifts.length} quà tặng`;
        } else {
            countTextEl.textContent = `Hiển thị: ${filteredGifts.length}/${gifts.length} quà tặng`;
        }
    }

    if (filteredGifts.length === 0) {
        emptyStateEl.classList.remove('hidden');
        return;
    }
    emptyStateEl.classList.add('hidden');

    // Adjust grid columns for reordering mode vs normal mode
    if (isReordering) {
        giftListEl.className = 'grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3 transition-all duration-300';
    } else {
        giftListEl.className = 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-6 transition-all duration-300';
    }

    filteredGifts.forEach((gift, index) => {
        const nameVi = gift.name && gift.name.vi ? gift.name.vi : 'Chưa có tên';
        const price = gift.priceRange || '0đ';
        const platformLabel = gift.platform || 'Xem Ngay';
        const badgeText = gift.badge || '';

        const card = document.createElement('div');
        // Compact card styling for reordering mode
        card.className = `gift-card bg-white dark:bg-white/5 border border-gray-200 dark:border-white/10 dark:backdrop-blur-md rounded-2xl overflow-hidden flex flex-col relative shadow-sm hover:shadow-xl transition-all duration-300 group ${isReordering ? 'cursor-grab active:cursor-grabbing border-2 border-primary/50 select-none' : 'hover:-translate-y-1'}`;
        card.dataset.id = gift.id;

        const imgUrl = gift.imageUrl || '';
        const imageErrorAttr = `onerror="this.src='https://via.placeholder.com/400x400/f3f4f6/9ca3af?text=GIFT'"`

        // Define primary color rgb (Pink) for backgrounds
        const primaryColor = '#EC4899';
        const primaryColorRgb = '236, 72, 153';

        const heroHeight = isReordering ? 'h-20 sm:h-24' : 'h-32 sm:h-40';

        card.innerHTML = `
            <!-- Image Hero Section -->
            <div class="${heroHeight} w-full relative overflow-hidden bg-gray-100 dark:bg-gray-800 transition-all duration-300 pointer-events-none" style="background-color: rgba(${primaryColorRgb}, 0.05)">
                <img src="${imgUrl}" draggable="false" alt="${nameVi}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500 pointer-events-none" ${imageErrorAttr}>
                
                <!-- Top Left Badges (Active Toggle & Gender) -->
                ${!isReordering ? `
                <div class="absolute top-2 left-2 z-20 flex items-center gap-1.5 pointer-events-auto">
                    <label class="cursor-pointer bg-black/60 backdrop-blur-md p-1 rounded-full border border-white/20 shadow-md flex items-center justify-center" title="${gift.isActive !== false ? 'Đang bật' : 'Đang tắt'}">
                        <input type="checkbox" ${gift.isActive !== false ? 'checked' : ''} onchange="toggleGiftActive('${gift.id}', this.checked)" class="sr-only peer">
                        <div class="relative w-7 h-4 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-3 after:w-3 after:transition-all peer-checked:bg-green-500 flex-shrink-0"></div>
                    </label>

                    ${gift.gender ? `
                    <div class="w-6 h-6 bg-black/60 backdrop-blur-md rounded-full flex items-center justify-center border border-white/20 shadow-sm">
                        <span class="text-xs leading-none" style="margin-top: 1px">${gift.gender === 'male' ? '♂️' : gift.gender === 'female' ? '♀️' : '⚧️'}</span>
                    </div>
                    ` : ''}
                </div>
                ` : ''}

                <!-- Popular Badge -->
                ${badgeText && !isReordering ? `
                <div class="absolute top-2 right-2 px-2 h-5 bg-gradient-to-r from-yellow-500 to-amber-600 rounded-md shadow-lg flex items-center justify-center pointer-events-auto">
                    <span class="text-[10px] font-bold text-white tracking-wider uppercase leading-none mt-[1px]">${badgeText}</span>
                </div>
                ` : ''}
                
                <!-- Overlay on hover -->
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"></div>
                
                <!-- Order Index Badge (Only in Reordering Mode) -->
                ${isReordering ? `
                <div class="absolute inset-0 bg-black/40 flex items-center justify-center z-20 pointer-events-none">
                    <div class="order-badge w-9 h-9 rounded-full bg-primary text-white flex items-center justify-center text-sm font-black shadow-lg border-2 border-white/40">${index + 1}</div>
                </div>
                ` : ''}
            </div>
            
            <!-- Info Section -->
            <div class="${isReordering ? 'p-2' : 'p-3'} flex flex-col flex-grow">
                <h3 class="${isReordering ? 'text-xs line-clamp-1 mb-1 font-semibold' : 'text-sm font-bold line-clamp-2 mb-3'} text-gray-900 dark:text-white leading-snug ${gift.isActive === false ? 'line-through opacity-60' : ''}" title="${nameVi}">${nameVi}</h3>
                
                <div class="mt-auto">
                    <div class="${isReordering ? 'text-xs font-bold mb-1' : 'text-sm font-black mb-2'}" style="color: ${primaryColor}">${price}</div>
                    ${!isReordering ? `
                    <div class="w-full py-1.5 rounded-lg border flex items-center justify-center gap-1.5 transition-colors mb-3" 
                         style="background-color: rgba(${primaryColorRgb}, 0.1); border-color: rgba(${primaryColorRgb}, 0.3)">
                        <i class="${gift.platform === 'Tiktok Shop' ? 'fa-brands fa-tiktok' : 'fa-solid fa-bag-shopping'} text-[11px]" style="color: ${primaryColor}"></i>
                        <span class="text-xs font-bold" style="color: ${primaryColor}">${platformLabel}</span>
                    </div>
                    ` : ''}
                </div>

                <!-- Admin Actions -->
                <div class="flex gap-2 ${isReordering ? 'pt-1.5' : 'pt-3'} border-t border-gray-100 dark:border-white/10 mt-auto">
                    ${isReordering ?
                `<div class="drag-handle w-full py-1 bg-primary/10 text-primary rounded-md text-[10px] font-bold flex justify-center items-center gap-1 cursor-grab">
                    <i class="fa-solid fa-arrows-up-down-left-right"></i> <span>Kéo xếp</span>
                 </div>` :
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
            animation: 200,
            draggable: '.gift-card',
            forceFallback: true,
            fallbackTolerance: 3,
            ghostClass: 'opacity-30',
            scroll: true,
            scrollSensitivity: 120,
            scrollSpeed: 25,
            bubbleScroll: true,
            onEnd: () => {
                const badges = giftListEl.querySelectorAll('.order-badge');
                badges.forEach((badge, idx) => {
                    badge.textContent = String(idx + 1);
                });
            }
        });
    }
}

// Delete
window.deleteGift = async (id) => {
    if (confirm('Bạn có chắc chắn muốn xóa món quà này?')) {
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
if (emptyStateBtn) {
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
    document.querySelectorAll('#f-categories input[type="checkbox"]').forEach(cb => {
        cb.checked = false;
        cb.parentElement.classList.remove('border-primary', 'bg-primary/5');
    });

    // Set checkboxes
    const categories = gift.categoryIds || [];
    document.querySelectorAll('#f-categories input[type="checkbox"]').forEach(cb => {
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
    const scrollContainer1 = giftModal.querySelector('.overflow-y-auto');
    if (scrollContainer1) scrollContainer1.scrollTop = 0;
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
    document.querySelectorAll('#f-categories input[type="checkbox"]').forEach(cb => cb.parentElement.classList.remove('border-primary', 'bg-primary/5'));
    document.querySelectorAll('.occasion-cb').forEach(cb => cb.parentElement.classList.remove('border-primary', 'bg-primary/5'));

    giftModal.classList.remove('hidden');
    const scrollContainer2 = giftModal.querySelector('.overflow-y-auto');
    if (scrollContainer2) scrollContainer2.scrollTop = 0;
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
    document.querySelectorAll('#f-categories input[type="checkbox"]').forEach(cb => {
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
// 4.5. DEPLOY VERSION LOGIC
// ==========================================
if (btnDeployVersion) {
    btnDeployVersion.addEventListener('click', async () => {
        if (!confirm("Bạn có chắc chắn muốn phát hành dữ liệu mới tới tất cả người dùng không?")) {
            return;
        }

        const icon = btnDeployVersion.querySelector('i');
        const oldClass = icon.className;
        icon.className = "fa-solid fa-spinner fa-spin";
        btnDeployVersion.disabled = true;

        try {
            await db.collection('settings').doc('data_version').set({
                version: firebase.firestore.FieldValue.increment(1)
            }, { merge: true });

            showToast("Đã phát hành bản cập nhật thành công!");
        } catch (e) {
            showToast("Lỗi khi phát hành cập nhật!", true);
            console.error(e);
        }

        icon.className = oldClass;
        btnDeployVersion.disabled = false;
    });
}

// ==========================================
// 5. REORDER LOGIC
// ==========================================
btnReorder.addEventListener('click', () => {
    isReordering = true;
    btnReorder.classList.add('hidden');
    btnSaveReorder.classList.remove('hidden');
    btnCancelReorder.classList.remove('hidden');
    
    const viewCat = document.getElementById('view-categories');
    const isCat = viewCat && !viewCat.classList.contains('hidden');
    
    if (isCat) {
        document.getElementById('btn-add-new-cat-trigger')?.classList.add('hidden');
        renderCategories();
    } else {
        btnAddNew.classList.add('hidden');
        // Disable filter inputs while dragging
        const searchInput = document.getElementById('gift-search-input');
        const filterCat = document.getElementById('gift-filter-category');
        if (searchInput) searchInput.disabled = true;
        if (filterCat) filterCat.disabled = true;

        const selectedCatName = filterCat && filterCat.value ? filterCat.options[filterCat.selectedIndex]?.text : '';
        if (selectedCatName && filterCat.value) {
            showToast(`Đang sắp xếp cho danh mục: ${selectedCatName}`);
        } else {
            showToast("Đang sắp xếp tất cả quà tặng");
        }
        renderGifts();
    }
});

btnCancelReorder.addEventListener('click', () => {
    isReordering = false;
    btnReorder.classList.remove('hidden');
    btnSaveReorder.classList.add('hidden');
    btnCancelReorder.classList.add('hidden');
    
    const viewCat = document.getElementById('view-categories');
    const isCat = viewCat && !viewCat.classList.contains('hidden');

    const searchInput = document.getElementById('gift-search-input');
    const filterCat = document.getElementById('gift-filter-category');
    if (searchInput) searchInput.disabled = false;
    if (filterCat) filterCat.disabled = false;
    
    if (isCat) {
        document.getElementById('btn-add-new-cat-trigger')?.classList.remove('hidden');
        loadCategories();
    } else {
        btnAddNew.classList.remove('hidden');
        loadGifts(); // reset order
    }
});

btnSaveReorder.addEventListener('click', async () => {
    btnSaveReorder.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
    btnSaveReorder.disabled = true;

    const searchInput = document.getElementById('gift-search-input');
    const filterCat = document.getElementById('gift-filter-category');
    if (searchInput) searchInput.disabled = false;
    if (filterCat) filterCat.disabled = false;

    try {
        const batch = db.batch();
        const viewCat = document.getElementById('view-categories');
        const isCat = viewCat && !viewCat.classList.contains('hidden');
        
        if (isCat) {
            const cards = document.querySelectorAll('.category-card');
            cards.forEach((card, index) => {
                const id = card.dataset.id;
                const ref = db.collection('gift_categories').doc(id);
                batch.update(ref, { order: index * 10 });
            });
        } else {
            const cards = giftListEl.querySelectorAll('.gift-card');
            cards.forEach((card, index) => {
                const id = card.dataset.id;
                const ref = db.collection('gifts').doc(id);
                batch.update(ref, { order: index * 10 });
            });
        }

        await batch.commit();
        
        const catName = filterCat && filterCat.value ? filterCat.options[filterCat.selectedIndex]?.text : '';
        if (catName && filterCat.value && !isCat) {
            showToast(`Đã lưu thứ tự cho danh mục: ${catName}`);
        } else {
            showToast("Đã lưu thứ tự hiển thị!");
        }

        isReordering = false;
        btnReorder.classList.remove('hidden');
        btnSaveReorder.classList.add('hidden');
        btnCancelReorder.classList.add('hidden');
        btnSaveReorder.innerHTML = '<i class="fa-solid fa-check"></i> Lưu thứ tự';
        btnSaveReorder.disabled = false;

        if (isCat) {
            document.getElementById('btn-add-new-cat-trigger')?.classList.remove('hidden');
            loadCategories();
        } else {
            btnAddNew.classList.remove('hidden');
            loadGifts(); // reload to get new orders
        }
    } catch (error) {
        console.error(error);
        showToast("Lỗi khi lưu thứ tự!", true);
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

function updateHeaderActionButtons(activeTabKey) {
    const btnGift = document.getElementById('btn-add-new');
    const btnReorder = document.getElementById('btn-reorder');
    const btnOccasion = document.getElementById('btn-add-new-occasion-trigger');
    const btnCategory = document.getElementById('btn-add-new-cat-trigger');
    const btnCategory2 = document.getElementById('btn-add-new-cat-trigger-2');
    const btnBanner = document.getElementById('btn-add-new-sb-trigger');
    const btnPromo = document.getElementById('btn-add-new-pc-trigger');

    const allBtns = [btnGift, btnReorder, btnOccasion, btnCategory, btnCategory2, btnBanner, btnPromo];
    allBtns.forEach(btn => {
        if (btn) {
            btn.style.display = 'none';
            btn.classList.add('hidden');
        }
    });

    if (activeTabKey === 'gifts') {
        if (btnGift) { btnGift.style.display = 'flex'; btnGift.classList.remove('hidden'); }
        if (btnReorder) { btnReorder.style.display = 'flex'; btnReorder.classList.remove('hidden'); }
    } else if (activeTabKey === 'occasions') {
        if (btnOccasion) { btnOccasion.style.display = 'flex'; btnOccasion.classList.remove('hidden'); }
    } else if (activeTabKey === 'categories') {
        if (btnCategory) { btnCategory.style.display = 'flex'; btnCategory.classList.remove('hidden'); }
        if (btnReorder) { btnReorder.style.display = 'flex'; btnReorder.classList.remove('hidden'); }
    } else if (activeTabKey === 'banner') {
        if (btnBanner) { btnBanner.style.display = 'flex'; btnBanner.classList.remove('hidden'); }
    } else if (activeTabKey === 'promo') {
        if (btnPromo) { btnPromo.style.display = 'flex'; btnPromo.classList.remove('hidden'); }
    }
}

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
        updateHeaderActionButtons('gifts');

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
        updateHeaderActionButtons('occasions');

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
            <div class="flex items-center justify-between gap-3">
                <div class="flex items-center gap-3 min-w-0">
                    <div class="w-12 h-12 rounded-xl flex items-center justify-center text-2xl shadow-inner flex-shrink-0" style="background: ${occ.gradient || 'gray'}">
                        ${occ.emoji || '✨'}
                    </div>
                    <div class="min-w-0">
                        <h3 class="text-lg font-bold text-gray-900 dark:text-white truncate ${occ.isActive === false ? 'line-through opacity-60' : ''}">${occ.nameVi}</h3>
                        <p class="text-sm text-gray-500 dark:text-gray-400">${occ.day} tháng ${occ.month}</p>
                    </div>
                </div>
                <label class="relative inline-flex items-center cursor-pointer flex-shrink-0" title="${occ.isActive !== false ? 'Đang bật' : 'Đang tắt'}">
                    <input type="checkbox" ${occ.isActive !== false ? 'checked' : ''} onchange="toggleOccasionActive('${occ.id}', this.checked)" class="sr-only peer">
                    <div class="relative w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all dark:border-gray-600 peer-checked:bg-green-500 shadow-sm flex-shrink-0"></div>
                </label>
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

    openOccasionModal();
};

// Delete Occasion
window.deleteOccasion = async (id) => {
    if (confirm('Bạn có chắc chắn muốn xóa sự kiện này?')) {
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
    const scrollContainer = occasionModal.querySelector('.overflow-y-auto');
    if (scrollContainer) scrollContainer.scrollTop = 0;
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
            gradient: document.getElementById('occ-gradient').value
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

window.openAssignProductsModal = (id, mode = 'occasion') => {
    let name = '';
    if (mode === 'category') {
        const cat = categories.find(c => c.id === id);
        if (!cat) return;
        name = cat.name;
    } else {
        const occ = specialOccasions.find(o => o.id === id);
        if (!occ) return;
        name = occ.nameVi;
    }

    document.getElementById('assign-modal-title-text').innerText = `Gán SP cho ${name}`;
    const idInput = document.getElementById('assign-occ-id');
    idInput.value = id;
    idInput.dataset.mode = mode;

    const listContainer = document.getElementById('assign-products-list');
    listContainer.innerHTML = '';
    initialAssignState = {};

    if (gifts.length === 0) {
        listContainer.innerHTML = '<p class="text-gray-500 text-center py-4">Chưa có sản phẩm nào.</p>';
    } else {
        gifts.forEach(gift => {
            const isSelected = mode === 'category'
                ? (gift.categoryIds && gift.categoryIds.includes(id))
                : (gift.occasionIds && gift.occasionIds.includes(id));

            initialAssignState[gift.id] = isSelected;

            const item = document.createElement('label');
            item.className = `flex items-center justify-between p-3 rounded-xl border ${isSelected ? 'border-primary bg-primary/5' : 'border-gray-200 dark:border-white/10 bg-white dark:bg-white/5'} cursor-pointer transition-colors`;
            item.innerHTML = `
                <div class="flex items-center gap-3 min-w-0">
                    <input type="checkbox" class="w-5 h-5 rounded border-gray-300 text-primary focus:ring-primary flex-shrink-0" value="${gift.id}" ${isSelected ? 'checked' : ''}>
                    <div class="min-w-0">
                        <p class="font-bold text-gray-900 dark:text-white truncate">${gift.name.vi || gift.name.en || 'No Name'}</p>
                        <p class="text-xs text-gray-500">${gift.priceRange || '0đ'}</p>
                    </div>
                </div>
                <img src="${gift.imageUrl}" class="w-10 h-10 rounded-lg object-cover bg-gray-100 flex-shrink-0" onerror="this.src='https://via.placeholder.com/40'">
            `;

            const checkbox = item.querySelector('input[type="checkbox"]');
            checkbox.addEventListener('change', () => {
                item.className = `flex items-center justify-between p-3 rounded-xl border ${checkbox.checked ? 'border-primary bg-primary/5' : 'border-gray-200 dark:border-white/10 bg-white dark:bg-white/5'} cursor-pointer transition-colors`;
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
        const idInput = document.getElementById('assign-occ-id');
        const id = idInput.value;
        const mode = idInput.dataset.mode || 'occasion';
        if (!id) return;

        btnSaveAssign.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
        btnSaveAssign.disabled = true;

        try {
            const checkboxes = document.querySelectorAll('#assign-products-list input[type="checkbox"]');
            const batch = db.batch();
            let updatesCount = 0;
            const targetField = mode === 'category' ? 'categoryIds' : 'occasionIds';

            checkboxes.forEach(chk => {
                const giftId = chk.value;
                const wasSelected = initialAssignState[giftId];
                const isSelected = chk.checked;

                if (isSelected && !wasSelected) {
                    const ref = db.collection('gifts').doc(giftId);
                    batch.update(ref, {
                        [targetField]: firebase.firestore.FieldValue.arrayUnion(id)
                    });
                    updatesCount++;
                } else if (!isSelected && wasSelected) {
                    const ref = db.collection('gifts').doc(giftId);
                    batch.update(ref, {
                        [targetField]: firebase.firestore.FieldValue.arrayRemove(id)
                    });
                    updatesCount++;
                }
            });

            if (updatesCount > 0) {
                await batch.commit();
                showToast("Đã cập nhật sản phẩm thành công!");
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
    } catch (e) {
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

        updateHeaderActionButtons('banner');

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
                <label class="absolute top-2 right-2 z-10 flex items-center cursor-pointer bg-black/60 backdrop-blur-md p-1 rounded-full border border-white/20 shadow-md" title="${item.isActive ? 'Đang bật' : 'Đang tắt'}">
                    <input type="checkbox" ${item.isActive ? 'checked' : ''} onchange="toggleStartupBannerItemActive('${item.id || index}', this.checked)" class="sr-only peer">
                    <div class="relative w-7 h-4 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-3 after:w-3 after:transition-all peer-checked:bg-green-500 flex-shrink-0"></div>
                </label>
            </div>
            <div class="p-4 flex flex-col flex-1">
                <h3 class="text-lg font-bold text-gray-900 dark:text-white line-clamp-1 mb-1 ${!item.isActive ? 'line-through opacity-60' : ''}">${item.title || '(Không tiêu đề)'}</h3>
                <p class="text-xs text-gray-500 dark:text-gray-400 mb-4"><i class="fa-solid fa-link mr-1"></i> ${item.actionType === 'gift'
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
        if (sbItemTitle) sbItemTitle.value = itemData.title || '';
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
    const scrollContainerSb = sbModal.querySelector('.overflow-y-auto');
    if (scrollContainerSb) scrollContainerSb.scrollTop = 0;
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

window.editSbItem = function (id) {
    const item = startupBannerData.items.find((x, idx) => (x.id === id) || (idx.toString() === id.toString()));
    if (item) openSbModal(true, { ...item, id });
}

window.deleteSbItem = function (id) {
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



// ==========================================
// CATEGORY MANAGEMENT
// ==========================================
let categories = [];
let isEditingCat = false;



// Load Categories
async function loadCategories() {
    loadingEl.style.display = 'block';
    try {
        const snap = await db.collection('gift_categories').orderBy('order').get();
        categories = [];
        let html = '';

        if (snap.empty) {
            document.getElementById('category-empty-state').classList.remove('hidden');
            document.getElementById('category-list-container').innerHTML = '';
        } else {
            document.getElementById('category-empty-state').classList.add('hidden');
            
            snap.forEach(doc => {
                const data = doc.data();
                data.id = doc.id;
                categories.push(data);
                
                const bgStyle = `background-color: ${intToHex(data.colorValue)}22;`;
                const textStyle = `color: ${intToHex(data.colorValue)};`;
                
                html += `
                <div class="bg-white dark:bg-darkcard rounded-2xl p-5 shadow-sm border border-gray-200 dark:border-darkborder hover:shadow-md transition-all flex flex-col gap-3 relative">
                    <div class="flex items-start justify-between gap-3">
                        <div class="flex items-start gap-4 min-w-0">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center text-2xl flex-shrink-0" style="${bgStyle}">
                                ${data.emoji || '📅'}
                            </div>
                            <div class="flex-1 min-w-0">
                                <h3 class="text-base font-bold text-gray-900 dark:text-white truncate ${!data.isActive ? 'line-through opacity-60' : ''}">${data.name}</h3>
                                <p class="text-sm text-gray-500 dark:text-gray-400 truncate mb-1">ID: ${data.id}</p>
                                <div class="flex flex-wrap gap-1">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800 dark:bg-white/10 dark:text-gray-300">
                                        Thứ tự: ${data.order || 99}
                                    </span>
                                    ${data.canSuggestProducts ? '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300">Gợi ý</span>' : ''}
                                </div>
                            </div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer flex-shrink-0" title="${data.isActive !== false ? 'Đang bật' : 'Đang tắt'}">
                            <input type="checkbox" ${data.isActive !== false ? 'checked' : ''} onchange="toggleCategoryActive('${data.id}', this.checked)" class="sr-only peer">
                            <div class="relative w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all dark:border-gray-600 peer-checked:bg-green-500 shadow-sm flex-shrink-0"></div>
                        </label>
                    </div>
                    
                    <div class="mt-auto pt-3 border-t border-gray-100 dark:border-white/10 flex flex-col gap-2">
                        <div class="flex gap-2">
                            <button onclick="editCategory('${data.id}')" class="flex-1 py-1.5 bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1">
                                <i class="fa-solid fa-pen-to-square"></i> Sửa
                            </button>
                            <button onclick="deleteCategory('${data.id}')" class="flex-1 py-1.5 bg-red-50 dark:bg-red-500/10 text-red-500 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1">
                                <i class="fa-solid fa-trash-can"></i> Xóa
                            </button>
                        </div>
                        <button class="w-full py-2.5 bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400 hover:bg-amber-100 dark:hover:bg-amber-500/20 rounded-lg transition-colors font-semibold text-sm flex justify-center items-center gap-2 mt-1" onclick="openAssignProductsModal('${data.id}', 'category')" title="Gán Sản Phẩm">
                            <i class="fa-solid fa-gift"></i> Gán Sản Phẩm
                        </button>
                    </div>
                </div>
                `;
            });
            document.getElementById('category-list-container').innerHTML = html;
            
            // Render dynamic categories in the gift modal form (Only active & canSuggestProducts === true)
            const fCats = document.getElementById('f-categories');
            if (fCats) {
                let htmlCats = '';
                categories.forEach(cat => {
                    if (cat.isActive === false || !cat.canSuggestProducts) return; // Only show active categories with Gợi Ý Quà Tặng = true
                    htmlCats += `
                    <label class="category-cb-wrapper flex items-center gap-2 p-3 rounded-xl border border-gray-200 dark:border-white/10 bg-gray-50 dark:bg-white/5 cursor-pointer transition-colors hover:border-primary/50 group">
                        <input type="checkbox" value="${cat.id}" class="hidden peer">
                        <div class="w-5 h-5 rounded flex-shrink-0 border-2 border-gray-300 dark:border-gray-500 peer-checked:bg-primary peer-checked:border-primary flex items-center justify-center transition-colors">
                            <i class="fa-solid fa-check text-white text-xs opacity-0 peer-checked:opacity-100"></i>
                        </div>
                        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">${cat.name} ${cat.emoji || '📅'}</span>
                    </label>`;
                });
                fCats.innerHTML = htmlCats;
                
                // Attach listeners
                fCats.querySelectorAll('input[type="checkbox"]').forEach(cb => {
                    cb.addEventListener('change', (e) => {
                        if (e.target.checked) e.target.parentElement.classList.add('border-primary', 'bg-primary/5');
                        else e.target.parentElement.classList.remove('border-primary', 'bg-primary/5');
                    });
                });
            }
            
            // Populate category filter in Gifts tab
            renderGiftCategoryFilter();
        }
    } catch (e) {
        console.error("Error loading categories:", e);
        showToast("Lỗi tải danh mục!", "error");
    }
    loadingEl.style.display = 'none';
}

let sortableCatInstance = null;

function renderCategories() {
    const container = document.getElementById('category-list-container');
    let html = '';
    
    if (categories.length === 0) {
        document.getElementById('category-empty-state').classList.remove('hidden');
        container.innerHTML = '';
        return;
    }
    document.getElementById('category-empty-state').classList.add('hidden');
    
    categories.forEach(data => {
        const bgStyle = `background-color: ${intToHex(data.colorValue)}22;`;
        const textStyle = `color: ${intToHex(data.colorValue)};`;
        const dragHandle = isReordering ? `<div class="drag-handle w-8 h-8 rounded-lg flex items-center justify-center text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-white/10 cursor-grab active:cursor-grabbing mr-3 transition-colors shrink-0"><i class="fa-solid fa-grip-vertical"></i></div>` : '';
        
        html += `
        <div class="category-card bg-white dark:bg-darkcard rounded-2xl p-5 shadow-sm border border-gray-200 
dark:border-darkborder hover:shadow-md transition-all group relative" data-id="${data.id}">
            <div class="flex items-start gap-4">
                ${dragHandle}
                <div class="w-12 h-12 rounded-xl flex items-center justify-center text-2xl flex-shrink-0" 
style="${bgStyle}">
                    ${data.emoji || '📅'}
                </div>
                <div class="flex-1 min-w-0">
                    <h3 class="text-base font-bold text-gray-900 dark:text-white truncate" 
style="${!data.isActive ? 'text-decoration: line-through;' : ''}">${data.name}</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400 truncate mb-1">ID: ${data.id}</p>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium 
bg-gray-100 text-gray-800 dark:bg-white/10 dark:text-gray-300">
                        Thứ tự: ${data.order || 99}
                    </span>
                    ${data.canSuggestProducts ? '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300 ml-1">Gợi Ý</span>' : ''}
                </div>
            </div>
            
            ${!isReordering ? `
            <div class="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <button onclick="editCategory('${data.id}')" class="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 dark:bg-blue-900/30 dark:text-blue-400 dark:hover:bg-blue-900/50 flex items-center justify-center transition-colors"><i class="fa-solid fa-pen"></i></button>
                <button onclick="deleteCategory('${data.id}')" class="w-8 h-8 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 dark:bg-red-900/30 dark:text-red-400 dark:hover:bg-red-900/50 flex items-center justify-center transition-colors"><i class="fa-solid fa-trash"></i></button>
            </div>` : ''}
        </div>
        `;
    });
    
    container.innerHTML = html;
    
    if (sortableCatInstance) sortableCatInstance.destroy();
    if (isReordering) {
        sortableCatInstance = new Sortable(container, {
            animation: 150,
            handle: '.drag-handle',
            ghostClass: 'sortable-ghost',
            scroll: true,
            scrollSensitivity: 120,
            scrollSpeed: 25,
            bubbleScroll: true
        });
    }
}

function intToHex(intValue) {
    if(!intValue) return '#10B981';
    let hex = intValue.toString(16);
    while (hex.length < 6) hex = "0" + hex;
    return "#" + hex;
}

// Add/Edit Modal
const btnAddCat1 = document.getElementById('btn-add-new-cat-trigger');
const btnAddCat2 = document.getElementById('btn-add-new-cat-trigger-2');
const modalCat = document.getElementById('modal-category');
const formCat = document.getElementById('form-category');
const btnSaveCat = document.getElementById('btn-save-cat');

modalCat?.querySelectorAll('.close-modal').forEach(btn => {
    btn.addEventListener('click', () => {
        modalCat.querySelector('.modal-content')?.classList.replace('scale-100', 'scale-95');
        modalCat.querySelector('.modal-content')?.classList.replace('opacity-100', 'opacity-0');
        setTimeout(() => {
            modalCat.classList.add('hidden');
        }, 300);
    });
});

window.selectCatEmoji = (emoji) => {
    const input = document.getElementById('cat-emoji');
    if (input) input.value = emoji;
};

function hexToColorInt(hexString) {
    if (!hexString) return 4279286145; // 0xFF10B981
    let hex = hexString.replace('#', '').trim();
    if (hex.length === 6) {
        hex = 'FF' + hex;
    }
    return parseInt(hex, 16);
}

window.selectCatColor = (hex) => {
    const picker = document.getElementById('cat-color-picker');
    const hexInput = document.getElementById('cat-color-hex');
    const valInput = document.getElementById('cat-colorValue');
    if (picker) picker.value = hex;
    if (hexInput) hexInput.value = hex.toUpperCase();
    if (valInput) valInput.value = hexToColorInt(hex);
};

document.getElementById('cat-color-picker')?.addEventListener('input', (e) => {
    const hex = e.target.value;
    const hexInput = document.getElementById('cat-color-hex');
    const valInput = document.getElementById('cat-colorValue');
    if (hexInput) hexInput.value = hex.toUpperCase();
    if (valInput) valInput.value = hexToColorInt(hex);
});

document.getElementById('cat-color-hex')?.addEventListener('input', (e) => {
    let hex = e.target.value.trim();
    if (!hex.startsWith('#')) hex = '#' + hex;
    if (/^#[0-9A-Fa-f]{6}$/.test(hex)) {
        const picker = document.getElementById('cat-color-picker');
        const valInput = document.getElementById('cat-colorValue');
        if (picker) picker.value = hex;
        if (valInput) valInput.value = hexToColorInt(hex);
    }
});

[btnAddCat1, btnAddCat2].forEach(btn => {
    btn?.addEventListener('click', () => {
        isEditingCat = false;
        formCat.reset();
        document.getElementById('cat-id').readOnly = false;
        document.getElementById('cat-order').value = 99;
        selectCatColor('#10B981');
        document.getElementById('modal-cat-title').textContent = "Thêm Danh Mục Mới";
        modalCat.classList.remove('hidden');
        const scrollContainer = modalCat.querySelector('.overflow-y-auto');
        if (scrollContainer) scrollContainer.scrollTop = 0;
        setTimeout(() => {
            modalCat.querySelector('.modal-content')?.classList.replace('scale-95', 'scale-100');
            modalCat.querySelector('.modal-content')?.classList.replace('opacity-0', 'opacity-100');
        }, 10);
    });
});

window.editCategory = (id) => {
    const cat = categories.find(c => c.id === id);
    if (!cat) return;
    isEditingCat = true;
    document.getElementById('modal-cat-title').textContent = "Sửa Danh Mục";
    
    document.getElementById('cat-id').value = cat.id;
    document.getElementById('cat-id').readOnly = true;
    document.getElementById('cat-name').value = cat.name || '';
    document.getElementById('cat-nameEn').value = cat.nameEn || '';
    document.getElementById('cat-emoji').value = cat.emoji || '📅';
    document.getElementById('cat-order').value = cat.order || 99;
    
    const hexColor = intToHex(cat.colorValue || 4279286145);
    selectCatColor(hexColor);

    document.getElementById('cat-canSuggest').checked = cat.canSuggestProducts || false;
    document.getElementById('cat-isActive').checked = cat.isActive !== false;
    
    modalCat.classList.remove('hidden');
    const scrollContainer = modalCat.querySelector('.overflow-y-auto');
    if (scrollContainer) scrollContainer.scrollTop = 0;
    setTimeout(() => {
        modalCat.querySelector('.modal-content')?.classList.replace('scale-95', 'scale-100');
        modalCat.querySelector('.modal-content')?.classList.replace('opacity-0', 'opacity-100');
    }, 10);
};

btnSaveCat?.addEventListener('click', async () => {
    if (!formCat.checkValidity()) {
        formCat.reportValidity();
        return;
    }
    
    const id = document.getElementById('cat-id').value.trim();
    const data = {
        name: document.getElementById('cat-name').value.trim(),
        nameEn: document.getElementById('cat-nameEn').value.trim(),
        emoji: document.getElementById('cat-emoji').value.trim(),
        order: parseInt(document.getElementById('cat-order').value) || 99,
        colorValue: parseInt(document.getElementById('cat-colorValue').value) || 1092163,
        canSuggestProducts: document.getElementById('cat-canSuggest').checked,
        isActive: document.getElementById('cat-isActive').checked,
    };
    
    const originalBtnHTML = btnSaveCat.innerHTML;
    btnSaveCat.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
    btnSaveCat.disabled = true;
    
    try {
        await db.collection('gift_categories').doc(id).set(data, { merge: true });
        modalCat.querySelector('.modal-content')?.classList.replace('scale-100', 'scale-95');
        modalCat.querySelector('.modal-content')?.classList.replace('opacity-100', 'opacity-0');
        setTimeout(() => modalCat.classList.add('hidden'), 300);
        showToast("Lưu danh mục thành công!");
        loadCategories();
    } catch(e) {
        console.error("Save error:", e);
        showToast("Lỗi khi lưu danh mục!", "error");
    } finally {
        btnSaveCat.innerHTML = originalBtnHTML;
        btnSaveCat.disabled = false;
    }
});

window.deleteCategory = async (id) => {
    if(confirm("Bạn có chắc chắn muốn XÓA danh mục này? Hãy cân nhắc ẨN (Inactive) thay vì xoá.")) {
        try {
            await db.collection('gift_categories').doc(id).delete();
            showToast("Đã xóa danh mục!");
            loadCategories();
        } catch(e) {
            console.error(e);
            showToast("Lỗi khi xóa!", "error");
        }
    }
};


// ==========================================
// CATEGORY TAB NAVIGATION FIX
// ==========================================
// ==========================================
// ==========================================
// ALL TABS NAVIGATION MANAGER
// ==========================================
document.addEventListener('click', (e) => {
    const tabCategories = document.getElementById('tab-categories');
    const viewCategories = document.getElementById('view-categories');
    const tabPromoCodes = document.getElementById('tab-promo-codes');
    const viewPromoCodes = document.getElementById('view-promo-codes');
    const tabUsers = document.getElementById('tab-users');
    const viewUsers = document.getElementById('view-users');

    const isTabCategories = e.target.closest('#tab-categories');
    const isTabGifts = e.target.closest('#tab-gifts');
    const isTabOccasions = e.target.closest('#tab-occasions');
    const isTabBanner = e.target.closest('#tab-startup-banner');
    const isTabPromoCodes = e.target.closest('#tab-promo-codes');
    const isTabUsers = e.target.closest('#tab-users');

    const inactive = "w-full flex items-center gap-3 px-4 py-3 text-sm font-semibold rounded-xl text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/5 transition-colors";

    if (isTabGifts || isTabOccasions || isTabBanner || isTabPromoCodes || isTabUsers) {
        if (viewCategories) viewCategories.classList.add('hidden');
        if (tabCategories) tabCategories.className = inactive;
        const btnCat = document.getElementById('btn-add-new-cat-trigger');
        if (btnCat) btnCat.classList.add('hidden');
    }

    if (isTabGifts || isTabOccasions || isTabBanner || isTabCategories || isTabUsers) {
        if (viewPromoCodes) viewPromoCodes.classList.add('hidden');
        if (tabPromoCodes) tabPromoCodes.className = inactive;
        const btnPc = document.getElementById('btn-add-new-pc-trigger');
        if (btnPc) btnPc.classList.add('hidden');
    }

    if (isTabGifts || isTabOccasions || isTabBanner || isTabCategories || isTabPromoCodes) {
        if (viewUsers) viewUsers.classList.add('hidden');
        if (tabUsers) tabUsers.className = inactive;
    }

    if (isTabUsers && viewUsers && tabUsers) {
        document.getElementById('view-gifts')?.classList.add('hidden');
        document.getElementById('view-occasions')?.classList.add('hidden');
        document.getElementById('view-startup-banner')?.classList.add('hidden');
        if (viewCategories) viewCategories.classList.add('hidden');
        if (viewPromoCodes) viewPromoCodes.classList.add('hidden');

        document.querySelectorAll('nav button').forEach(btn => {
            btn.className = inactive;
        });

        tabUsers.className = "w-full flex items-center gap-3 px-4 py-3 text-sm font-semibold rounded-xl bg-primary/10 text-primary transition-colors";
        viewUsers.classList.remove('hidden');

        const titleEl = document.getElementById('page-title');
        if (titleEl) titleEl.textContent = "Quản Lý Người Dùng";

        // Hide sidebar on mobile
        const sidebar = document.getElementById('sidebar');
        const sidebarOverlay = document.getElementById('sidebar-overlay');
        if (window.innerWidth < 1024 && sidebar) {
            sidebar.classList.add('-translate-x-full');
            if (sidebarOverlay) sidebarOverlay.classList.add('hidden');
        }

        renderUsersDashboard();
    } else if (isTabCategories && viewCategories && tabCategories) {
        document.getElementById('view-gifts')?.classList.add('hidden');
        document.getElementById('view-occasions')?.classList.add('hidden');
        document.getElementById('view-startup-banner')?.classList.add('hidden');
        if (viewPromoCodes) viewPromoCodes.classList.add('hidden');
        if (viewUsers) viewUsers.classList.add('hidden');
        
        document.querySelectorAll('nav button').forEach(btn => {
            btn.className = inactive;
        });

        tabCategories.className = "w-full flex items-center gap-3 px-4 py-3 text-sm font-semibold rounded-xl bg-primary/10 text-primary transition-colors";
        viewCategories.classList.remove('hidden');
        document.getElementById('page-title').textContent = "Danh Mục Quà Tặng";
        
        updateHeaderActionButtons('categories');
        
        // Hide sidebar on mobile
        const sidebar = document.getElementById('sidebar');
        const sidebarOverlay = document.getElementById('sidebar-overlay');
        if(window.innerWidth < 1024 && sidebar) {
            sidebar.classList.add('-translate-x-full');
            if(sidebarOverlay) sidebarOverlay.classList.add('hidden');
        }
        
        loadCategories();
    } else if (isTabPromoCodes && viewPromoCodes && tabPromoCodes) {
        document.getElementById('view-gifts')?.classList.add('hidden');
        document.getElementById('view-occasions')?.classList.add('hidden');
        document.getElementById('view-startup-banner')?.classList.add('hidden');
        if (viewCategories) viewCategories.classList.add('hidden');
        if (viewUsers) viewUsers.classList.add('hidden');
        
        document.querySelectorAll('nav button').forEach(btn => {
            btn.className = inactive;
        });

        tabPromoCodes.className = "w-full flex items-center gap-3 px-4 py-3 text-sm font-semibold rounded-xl bg-primary/10 text-primary transition-colors";
        
        viewPromoCodes.classList.remove('hidden');
        document.getElementById('page-title').textContent = "Quản lý Promo Codes";
        
        updateHeaderActionButtons('promo');
        
        // Hide sidebar on mobile
        const sidebar = document.getElementById('sidebar');
        const sidebarOverlay = document.getElementById('sidebar-overlay');
        if(window.innerWidth < 1024 && sidebar) {
            sidebar.classList.add('-translate-x-full');
            if(sidebarOverlay) sidebarOverlay.classList.add('hidden');
        }
        
        loadPromoCodes();
    }
}, true);

// ==========================================
// 11. PROMO CODES MANAGEMENT LOGIC
// ==========================================
let promoCodesList = [];
const btnAddNewPc = document.getElementById('btn-add-new-pc-trigger');
const btnAddPcEmpty = document.getElementById('btn-add-pc-empty');
const pcModal = document.getElementById('pc-modal');
const pcForm = document.getElementById('pc-form');
const btnSavePc = document.getElementById('btn-save-pc');
const pcSearchInput = document.getElementById('pc-search-input');
const pcFilterType = document.getElementById('pc-filter-type');
const pcListContainer = document.getElementById('pc-list-container');
const pcEmptyState = document.getElementById('pc-empty-state');

// Effect dropdown wrap toggler
const pcTypeSelect = document.getElementById('pc-type');
if (pcTypeSelect) {
    pcTypeSelect.addEventListener('change', () => {
        const wrap = document.getElementById('pc-effect-wrap');
        if (wrap) {
            wrap.classList.toggle('hidden', pcTypeSelect.value !== 'giftEffect');
        }
    });
}

function loadPromoCodes() {
    loadingEl.style.display = 'block';
    pcListContainer.innerHTML = '';
    pcEmptyState.classList.add('hidden');

    db.collection('promo_codes').onSnapshot(snapshot => {
        promoCodesList = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            data.id = doc.id;
            promoCodesList.push(data);
        });

        renderPromoCodes();
    }, error => {
        showToast("Lỗi tải dữ liệu Promo Codes", true);
        console.error(error);
        loadingEl.style.display = 'none';
    });
}

function renderPromoCodes() {
    loadingEl.style.display = 'none';
    pcListContainer.innerHTML = '';

    const query = pcSearchInput ? pcSearchInput.value.trim().toUpperCase() : '';
    const filter = pcFilterType ? pcFilterType.value : 'all';

    const filtered = promoCodesList.filter(item => {
        const matchesQuery = item.code && item.code.toUpperCase().includes(query);
        const matchesFilter = filter === 'all' || item.type === filter;
        return matchesQuery && matchesFilter;
    });

    if (filtered.length === 0) {
        pcEmptyState.classList.remove('hidden');
        return;
    }
    pcEmptyState.classList.add('hidden');

    filtered.forEach(item => {
        const code = item.code || '';
        const type = item.type || 'premium';
        const description = item.description || 'Quà tặng từ server';
        const maxUsage = item.maxUsage !== undefined && item.maxUsage !== null ? item.maxUsage : '∞';
        const usedCount = item.usedCount || 0;
        const durationDays = item.durationDays || null;
        
        let expText = 'Vĩnh viễn (Không hạn)';
        if (item.expirationDate) {
            const date = item.expirationDate.toDate ? item.expirationDate.toDate() : new Date(item.expirationDate);
            expText = date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
        }

        let typeBadgeColor = 'bg-green-500/20 text-green-400 border-green-500/40';
        if (type === 'giftEffect') typeBadgeColor = 'bg-pink-500/20 text-pink-400 border-pink-500/40';
        else if (type === 'testMode') typeBadgeColor = 'bg-amber-500/20 text-amber-400 border-amber-500/40';
        else if (type === 'admin') typeBadgeColor = 'bg-red-500/20 text-red-400 border-red-500/40';

        const card = document.createElement('div');
        card.className = 'bg-white dark:bg-darkcard border border-gray-200 dark:border-darkborder rounded-2xl p-5 relative shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col gap-3';
        
        card.innerHTML = `
            <div class="flex justify-between items-start gap-2">
                <h3 class="text-lg font-bold text-gray-900 dark:text-white tracking-wide ${item.isActive === false ? 'line-through opacity-60' : ''}">${code}</h3>
                <div class="flex items-center gap-2 flex-shrink-0">
                    <span class="px-2 py-0.5 text-xs font-bold uppercase rounded border ${typeBadgeColor}">${type}</span>
                    <label class="relative inline-flex items-center cursor-pointer" title="${item.isActive !== false ? 'Đang bật' : 'Đang tắt'}">
                        <input type="checkbox" ${item.isActive !== false ? 'checked' : ''} onchange="togglePromoCodeActive('${item.id}', this.checked)" class="sr-only peer">
                        <div class="relative w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all dark:border-gray-600 peer-checked:bg-green-500 shadow-sm flex-shrink-0"></div>
                    </label>
                </div>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-300">${description}</p>
            <div class="border-t border-gray-100 dark:border-white/10 my-1"></div>
            <div class="grid grid-cols-2 gap-2 text-xs text-gray-500 dark:text-gray-400">
                <div><i class="fa-solid fa-users mr-1"></i> Lượt: <b>${usedCount} / ${maxUsage}</b></div>
                ${durationDays ? `<div><i class="fa-solid fa-clock mr-1"></i> Hạn dùng: <b>${durationDays} ngày</b></div>` : ''}
                <div class="col-span-2"><i class="fa-solid fa-calendar-xmark mr-1"></i> Hạn nhập: <b>${expText}</b></div>
                ${type === 'giftEffect' && item.unlockedEffectId ? `<div class="col-span-2 text-pink-400"><i class="fa-solid fa-wand-magic-sparkles mr-1"></i> Hiệu ứng: <b>${item.unlockedEffectId}</b></div>` : ''}
            </div>
            <div class="mt-auto pt-3 border-t border-gray-100 dark:border-white/10 flex gap-2">
                <button class="flex-1 py-1.5 bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="editPromoCode('${item.id}')">
                    <i class="fa-solid fa-pen-to-square"></i> Sửa
                </button>
                <button class="flex-1 py-1.5 bg-red-50 dark:bg-red-500/10 text-red-500 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/20 rounded-lg transition-colors font-semibold text-xs flex justify-center items-center gap-1" onclick="deletePromoCode('${item.id}')">
                    <i class="fa-solid fa-trash-can"></i> Xóa
                </button>
            </div>
        `;
        pcListContainer.appendChild(card);
    });
}

if (pcSearchInput) pcSearchInput.addEventListener('input', renderPromoCodes);
if (pcFilterType) pcFilterType.addEventListener('change', renderPromoCodes);

function openPcModal(isEdit = false, itemData = null) {
    const codeInput = document.getElementById('pc-code');
    const effectWrap = document.getElementById('pc-effect-wrap');

    if (isEdit && itemData) {
        document.getElementById('modal-title-pc').innerHTML = '<i class="fa-solid fa-pen text-orange-500"></i> <span>Sửa Promo Code</span>';
        document.getElementById('pc-doc-id').value = itemData.id || '';
        if (codeInput) {
            codeInput.value = itemData.code || '';
            codeInput.disabled = true; // Can't change code string to avoid DB key mismatch
        }
        document.getElementById('pc-type').value = itemData.type || 'premium';
        document.getElementById('pc-description').value = itemData.description || '';
        document.getElementById('pc-descriptionEn').value = itemData.descriptionEn || '';
        document.getElementById('pc-maxUsage').value = itemData.maxUsage || '';
        document.getElementById('pc-durationDays').value = itemData.durationDays || '';
        
        if (itemData.expirationDate) {
            const date = itemData.expirationDate.toDate ? itemData.expirationDate.toDate() : new Date(itemData.expirationDate);
            // Format to YYYY-MM-DDTHH:MM
            const localISOTime = new Date(date.getTime() - (date.getTimezoneOffset() * 60000)).toISOString().slice(0, 16);
            document.getElementById('pc-expirationDate').value = localISOTime;
        } else {
            document.getElementById('pc-expirationDate').value = '';
        }

        if (itemData.type === 'giftEffect') {
            document.getElementById('pc-effectId').value = itemData.unlockedEffectId || 'hearts';
            if (effectWrap) effectWrap.classList.remove('hidden');
        } else {
            if (effectWrap) effectWrap.classList.add('hidden');
        }
    } else {
        document.getElementById('modal-title-pc').innerHTML = '<i class="fa-solid fa-ticket text-orange-500"></i> <span>Thêm Promo Code Mới</span>';
        if (pcForm) pcForm.reset();
        document.getElementById('pc-doc-id').value = '';
        document.getElementById('pc-descriptionEn').value = '';
        if (codeInput) {
            codeInput.disabled = false;
        }
        if (effectWrap) effectWrap.classList.add('hidden');
    }

    pcModal.classList.remove('hidden');
    const scrollContainerPc = pcModal.querySelector('.overflow-y-auto');
    if (scrollContainerPc) scrollContainerPc.scrollTop = 0;
    setTimeout(() => {
        pcModal.querySelector('.modal-content')?.classList.remove('scale-95', 'opacity-0');
        pcModal.querySelector('.modal-content')?.classList.add('scale-100', 'opacity-100');
    }, 10);
}

function closePcModalFunc() {
    const content = pcModal.querySelector('.modal-content');
    if (content) {
        content.classList.remove('scale-100', 'opacity-100');
        content.classList.add('scale-95', 'opacity-0');
    }
    setTimeout(() => {
        pcModal.classList.add('hidden');
        if (pcForm) pcForm.reset();
    }, 300);
}

if (pcModal) {
    pcModal.querySelectorAll('.close-modal').forEach(btn => {
        btn.addEventListener('click', closePcModalFunc);
    });
}

if (btnAddNewPc) btnAddNewPc.addEventListener('click', () => openPcModal(false));
if (btnAddPcEmpty) btnAddPcEmpty.addEventListener('click', () => openPcModal(false));

window.editPromoCode = function (id) {
    const item = promoCodesList.find(x => x.id === id);
    if (item) openPcModal(true, item);
};

window.deletePromoCode = async function (id) {
    if (confirm('Bạn có chắc chắn muốn xóa Promo Code này? Thao tác này không thể hoàn tác.')) {
        try {
            await db.collection('promo_codes').doc(id).delete();
            showToast("Đã xóa Promo Code!");
        } catch (e) {
            console.error(e);
            showToast("Lỗi khi xóa Promo Code", true);
        }
    }
};

if (btnSavePc) {
    btnSavePc.addEventListener('click', async () => {
        if (pcForm && !pcForm.reportValidity()) {
            return;
        }

        const id = document.getElementById('pc-doc-id').value;
        const codeInput = document.getElementById('pc-code');
        const code = codeInput ? codeInput.value.trim().toUpperCase() : '';
        const type = document.getElementById('pc-type').value;
        const description = document.getElementById('pc-description').value.trim();
        const descriptionEn = document.getElementById('pc-descriptionEn').value.trim();
        const maxUsageVal = document.getElementById('pc-maxUsage').value;
        const durationDaysVal = document.getElementById('pc-durationDays').value;
        const expirationDateVal = document.getElementById('pc-expirationDate').value;

        if (code.length < 5) {
            showToast("Mã code phải từ 5 ký tự trở lên!", true);
            return;
        }

        const maxUsage = maxUsageVal ? parseInt(maxUsageVal) : null;
        const durationDays = durationDaysVal ? parseFloat(durationDaysVal) : null;
        const expirationDate = expirationDateVal ? firebase.firestore.Timestamp.fromDate(new Date(expirationDateVal)) : null;

        const data = {
            code: code,
            type: type,
            description: description || null,
            descriptionEn: descriptionEn || null,
            maxUsage: maxUsage,
            durationDays: durationDays,
            expirationDate: expirationDate,
        };

        if (type === 'giftEffect') {
            data.unlockedEffectId = document.getElementById('pc-effectId').value;
        } else {
            // Delete field from firestore on update or set null
            data.unlockedEffectId = null;
        }

        btnSavePc.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang lưu...';
        btnSavePc.disabled = true;

        try {
            const docId = id || code;

            if (!id) {
                // Creating new, check duplicate
                const doc = await db.collection('promo_codes').doc(docId).get();
                if (doc.exists) {
                    showToast("Mã code này đã tồn tại trên hệ thống!", true);
                    btnSavePc.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Lưu Lại';
                    btnSavePc.disabled = false;
                    return;
                }
                data.usedCount = 0;
            }

            await db.collection('promo_codes').doc(docId).set(data, { merge: true });
            showToast(id ? "Đã cập nhật promo code!" : "Đã thêm promo code mới!");
            closePcModalFunc();
        } catch (e) {
            console.error(e);
            showToast("Lỗi khi lưu Promo Code", true);
        } finally {
            btnSavePc.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Lưu Lại';
            btnSavePc.disabled = false;
        }
    });
}

// ==========================================
// 12. ITEM ACTIVE TOGGLE HANDLERS
// ==========================================
window.toggleGiftActive = async (id, isActive) => {
    try {
        await db.collection('gifts').doc(id).update({ isActive: isActive });
        const g = gifts.find(x => x.id === id);
        if (g) g.isActive = isActive;
        showToast(isActive ? "Đã bật hiển thị quà tặng!" : "Đã tắt quà tặng!");
        renderGifts();
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật trạng thái quà tặng!", "error");
    }
};

window.toggleOccasionActive = async (id, isActive) => {
    try {
        await db.collection('special_occasions').doc(id).update({ isActive: isActive });
        const item = specialOccasions.find(x => x.id === id);
        if (item) item.isActive = isActive;
        showToast(isActive ? "Đã bật sự kiện!" : "Đã tắt sự kiện!");
        renderOccasions();
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật trạng thái sự kiện!", "error");
    }
};

window.toggleCategoryActive = async (id, isActive) => {
    try {
        await db.collection('gift_categories').doc(id).update({ isActive: isActive });
        const item = categories.find(x => x.id === id);
        if (item) item.isActive = isActive;
        showToast(isActive ? "Đã bật danh mục!" : "Đã tắt danh mục!");
        loadCategories();
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật trạng thái danh mục!", "error");
    }
};

window.toggleStartupBannerItemActive = async (id, isActive) => {
    try {
        const item = startupBannerData.items.find((x, idx) => (x.id === id) || (idx.toString() === id.toString()));
        if (item) {
            item.isActive = isActive;
            await saveStartupBannerData(false);
            showToast(isActive ? "Đã bật banner!" : "Đã tắt banner!");
        }
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật trạng thái banner!", "error");
    }
};

window.togglePromoCodeActive = async (id, isActive) => {
    try {
        await db.collection('promo_codes').doc(id).update({ isActive: isActive });
        const item = promoCodesList.find(x => x.id === id);
        if (item) item.isActive = isActive;
        showToast(isActive ? "Đã bật promo code!" : "Đã tắt promo code!");
        renderPromoCodes();
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật trạng thái promo code!", "error");
    }
};

document.getElementById('gift-search-input')?.addEventListener('input', renderGifts);
document.getElementById('gift-filter-category')?.addEventListener('change', renderGifts);

// Lock background body scroll when any modal is open
const modalScrollObserver = new MutationObserver(() => {
    const hasOpenModal = Array.from(document.querySelectorAll('.modal-overlay')).some(m => !m.classList.contains('hidden'));
    if (hasOpenModal) {
        document.body.style.overflow = 'hidden';
    } else {
        document.body.style.overflow = '';
    }
});

document.querySelectorAll('.modal-overlay').forEach(modal => {
    modalScrollObserver.observe(modal, { attributes: true, attributeFilter: ['class'] });
});

// ==========================================
// USER MANAGEMENT DASHBOARD LOGIC
// ==========================================
const tabUsers = document.getElementById('tab-users');
const viewUsers = document.getElementById('view-users');
const userSearchInput = document.getElementById('user-search-input');
const userFilterChips = document.getElementById('user-filter-chips');
const userListEl = document.getElementById('user-list');
const userDetailModal = document.getElementById('user-detail-modal');

if (tabUsers) {
    tabUsers.addEventListener('click', () => {
        if (pageTitle) pageTitle.textContent = "Quản Lý Người Dùng";

        // Hide other views
        const views = ['view-gifts', 'view-occasions', 'view-categories', 'view-startup-banner', 'view-promo-codes'];
        views.forEach(vId => {
            const el = document.getElementById(vId);
            if (el) el.classList.add('hidden');
        });
        if (viewUsers) viewUsers.classList.remove('hidden');

        // Style tab buttons
        document.querySelectorAll('nav button').forEach(btn => {
            btn.classList.remove('bg-primary/10', 'text-primary');
            btn.classList.add('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
        });
        tabUsers.classList.add('bg-primary/10', 'text-primary');
        tabUsers.classList.remove('text-gray-500', 'hover:bg-gray-100', 'dark:text-gray-400', 'dark:hover:bg-white/5');
    });
}

function loadUsersData() {
    if (userListenerUnsubscribe) userListenerUnsubscribe();

    userListenerUnsubscribe = db.collection('users').onSnapshot(snap => {
        allUsersData = [];
        snap.forEach(doc => {
            const data = doc.data();
            data.uid = doc.id;
            allUsersData.push(data);
        });
        renderUsersDashboard();
    }, err => {
        console.error("Error loading users:", err);
        showToast("Lỗi tải danh sách người dùng", true);
    });
}

if (userFilterChips) {
    userFilterChips.querySelectorAll('.user-chip').forEach(btn => {
        btn.addEventListener('click', () => {
            userFilterChips.querySelectorAll('.user-chip').forEach(b => {
                b.classList.remove('active', 'bg-primary', 'text-white', 'shadow-sm');
                b.classList.add('bg-gray-100', 'dark:bg-white/5', 'text-gray-600', 'dark:text-gray-300');
            });
            btn.classList.add('active', 'bg-primary', 'text-white', 'shadow-sm');
            btn.classList.remove('bg-gray-100', 'dark:bg-white/5', 'text-gray-600', 'dark:text-gray-300');
            currentUserFilter = btn.dataset.filter || 'all';
            renderUsersDashboard();
        });
    });
}

if (userSearchInput) {
    userSearchInput.addEventListener('input', (e) => {
        currentSearchQuery = e.target.value.trim().toLowerCase();
        renderUsersDashboard();
    });
}

function renderUsersDashboard() {
    if (!userListEl) return;

    // Manager role filters out anonymous users first
    let targetUsers = isManager 
        ? allUsersData.filter(u => u.isAnonymous !== true && (u.email || '').trim().length > 0)
        : [...allUsersData];

    // Compute stats
    let totalCount = targetUsers.length;
    let premiumCount = 0;
    let freeCount = 0;
    let googleCount = 0;
    let anonCount = 0;
    let superAdminCount = 0;
    let adminCount = 0;
    let managerCount = 0;
    let userRoleCount = 0;

    targetUsers.forEach(u => {
        const unlocked = Array.isArray(u.unlocked_features) ? u.unlocked_features : [];
        const isPrem = unlocked.includes('premium');
        if (isPrem) premiumCount++;
        else freeCount++;

        const isAnon = u.isAnonymous === true || !(u.email || '').trim();
        if (isAnon) anonCount++;
        else googleCount++;

        const role = (u.role || '').toLowerCase();
        if (role === 'super_admin') superAdminCount++;
        else if (role === 'admin') adminCount++;
        else if (role === 'manager') managerCount++;
        else userRoleCount++;
    });

    const elTotal = document.getElementById('stat-total-users');
    const elPrem = document.getElementById('stat-premium-users');
    const elFree = document.getElementById('stat-free-users');
    const cntAll = document.getElementById('cnt-all');
    const cntGoogle = document.getElementById('cnt-google');
    const cntAnon = document.getElementById('cnt-anon');
    const cntPrem = document.getElementById('cnt-premium');
    const cntFree = document.getElementById('cnt-free');
    const cntSuperAdmin = document.getElementById('cnt-superadmin');
    const cntAdmin = document.getElementById('cnt-admin');
    const cntManager = document.getElementById('cnt-manager');
    const cntUserRole = document.getElementById('cnt-userrole');

    if (elTotal) elTotal.textContent = totalCount;
    if (elPrem) elPrem.textContent = premiumCount;
    if (elFree) elFree.textContent = freeCount;
    if (cntAll) cntAll.textContent = totalCount;
    if (cntGoogle) cntGoogle.textContent = googleCount;
    if (cntAnon) cntAnon.textContent = anonCount;
    if (cntPrem) cntPrem.textContent = premiumCount;
    if (cntFree) cntFree.textContent = freeCount;
    if (cntSuperAdmin) cntSuperAdmin.textContent = superAdminCount;
    if (cntAdmin) cntAdmin.textContent = adminCount;
    if (cntManager) cntManager.textContent = managerCount;
    if (cntUserRole) cntUserRole.textContent = userRoleCount;

    // Filter by selected chip & query
    const filtered = targetUsers.filter(u => {
        const email = (u.email || '').toLowerCase();
        const name = (u.displayName || '').toLowerCase();
        const uid = (u.uid || '').toLowerCase();
        const matchesQuery = !currentSearchQuery || email.includes(currentSearchQuery) || name.includes(currentSearchQuery) || uid.includes(currentSearchQuery);

        const unlocked = Array.isArray(u.unlocked_features) ? u.unlocked_features : [];
        const isPrem = unlocked.includes('premium');
        const isAnon = u.isAnonymous === true || !email;
        const role = (u.role || '').toLowerCase();

        let matchesChip = true;
        if (currentUserFilter === 'google') matchesChip = !isAnon;
        else if (currentUserFilter === 'anon') matchesChip = isAnon;
        else if (currentUserFilter === 'premium') matchesChip = isPrem;
        else if (currentUserFilter === 'free') matchesChip = !isPrem;
        else if (currentUserFilter === 'super_admin') matchesChip = (role === 'super_admin');
        else if (currentUserFilter === 'admin') matchesChip = (role === 'admin');
        else if (currentUserFilter === 'manager') matchesChip = (role === 'manager');
        else if (currentUserFilter === 'user_role') matchesChip = (role !== 'super_admin' && role !== 'admin' && role !== 'manager');

        return matchesQuery && matchesChip;
    });

    if (filtered.length === 0) {
        userListEl.innerHTML = `
            <div class="col-span-full text-center py-16 bg-white dark:bg-darkcard rounded-2xl border border-gray-200 dark:border-darkborder shadow-sm">
                <i class="fa-solid fa-user-slash text-4xl text-gray-400 mb-3"></i>
                <h4 class="text-base font-bold text-gray-700 dark:text-gray-300">Không tìm thấy người dùng phù hợp</h4>
            </div>`;
        return;
    }

    let html = '';
    filtered.forEach(u => {
        const uid = u.uid || '';
        const email = u.email || '';
        const displayName = u.displayName || '';
        const photoUrl = u.photoUrl || '';
        const role = (u.role || '').toLowerCase();
        const isBlocked = u.is_blocked === true;
        const unlocked = Array.isArray(u.unlocked_features) ? u.unlocked_features : [];
        const isPremium = unlocked.includes('premium');
        const anniversaries = Array.isArray(u.anniversaries) ? u.anniversaries.length : 0;
        const isAnon = u.isAnonymous === true || !email;

        // Frame Border & Glow logic
        let borderColor = 'border-gray-200 dark:border-white/10';
        let glowStyle = '';
        let emoji = '👤';

        if (isBlocked) {
            borderColor = 'border-red-500';
            glowStyle = 'box-shadow: 0 0 10px rgba(239, 68, 68, 0.4);';
            emoji = '🚫';
        } else if (role === 'super_admin') {
            borderColor = 'border-purple-400';
            glowStyle = 'box-shadow: 0 0 10px rgba(139, 92, 246, 0.5);';
            emoji = '👑';
        } else if (role === 'admin') {
            borderColor = 'border-emerald-400';
            glowStyle = 'box-shadow: 0 0 10px rgba(16, 185, 129, 0.5);';
            emoji = '🛡️';
        } else if (role === 'manager') {
            borderColor = 'border-blue-400';
            glowStyle = 'box-shadow: 0 0 10px rgba(59, 130, 246, 0.5);';
            emoji = '👔';
        } else if (isPremium) {
            borderColor = 'border-amber-400';
            glowStyle = 'box-shadow: 0 0 10px rgba(245, 158, 11, 0.4);';
            emoji = '👤';
        }

        // Expirations format
        let premLabel = 'Miễn phí';
        if (isPremium) {
            premLabel = 'VIP Vĩnh viễn';
            if (u.expirations && u.expirations.premium) {
                const exp = u.expirations.premium;
                let expDate = null;
                if (exp.toDate) expDate = exp.toDate();
                else if (typeof exp === 'string') expDate = new Date(exp);
                if (expDate) premLabel = `VIP đến ${expDate.getDate()}/${expDate.getMonth()+1}/${expDate.getFullYear()}`;
            }
        }

        const initial = displayName ? displayName[0].toUpperCase() : 'U';

        html += `
            <div onclick="openUserDetailModal('${uid}')" class="bg-white dark:bg-darkcard border border-gray-200 dark:border-darkborder rounded-2xl p-4 shadow-sm hover:shadow-xl transition-all duration-300 cursor-pointer relative group">
                <div class="flex items-center gap-3">
                    <div class="relative shrink-0">
                        <div class="w-12 h-12 rounded-full border-2 ${borderColor} p-0.5" style="${glowStyle}">
                            ${photoUrl ? `<img src="${photoUrl}" class="w-full h-full rounded-full object-cover">` : `<div class="w-full h-full rounded-full bg-primary/20 flex items-center justify-center font-bold text-primary text-base">${initial}</div>`}
                        </div>
                        <span class="absolute -right-1 -bottom-1 w-5 h-5 rounded-full bg-darkcard border border-white/20 flex items-center justify-center text-[10px] shadow-sm">${emoji}</span>
                    </div>
                    <div class="min-w-0 flex-1">
                        <h4 class="text-sm font-bold text-gray-900 dark:text-white truncate">${email ? email : (isAnon ? 'Tài khoản ẩn danh' : 'Người dùng')}</h4>
                        ${displayName && displayName !== 'Người dùng' && displayName !== 'User Ẩn Danh' ? `<p class="text-xs text-gray-500 dark:text-gray-400 truncate mt-0.5">${displayName}</p>` : ''}
                    </div>
                    <i class="fa-solid fa-chevron-right text-xs text-gray-400 opacity-60 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all"></i>
                </div>

                <div class="border-t border-gray-100 dark:border-white/10 my-3"></div>

                <div class="grid grid-cols-2 gap-2 text-xs">
                    <div class="px-2.5 py-1.5 rounded-lg ${isPremium ? 'bg-amber-500/10 text-amber-500 border border-amber-500/30' : 'bg-gray-100 dark:bg-white/5 text-gray-500 dark:text-gray-400'} font-semibold truncate flex items-center gap-1.5">
                        <i class="fa-solid ${isPremium ? 'fa-award' : 'fa-user'}"></i>
                        <span class="truncate">${premLabel}</span>
                    </div>
                    <div class="px-2.5 py-1.5 rounded-lg bg-blue-500/10 text-blue-500 border border-blue-500/20 font-semibold truncate flex items-center gap-1.5">
                        <i class="fa-solid fa-calendar-days"></i>
                        <span>${anniversaries} sự kiện</span>
                    </div>
                </div>

                <div onclick="event.stopPropagation(); copyTextToClipboard('${uid}', 'Đã sao chép UID!')" class="mt-3 flex items-center justify-between text-[11px] text-gray-400 hover:text-primary transition-colors p-1.5 rounded-lg hover:bg-gray-50 dark:hover:bg-white/5">
                    <span class="font-mono truncate"><i class="fa-solid fa-fingerprint mr-1 opacity-70"></i> UID: ${uid}</span>
                    <i class="fa-solid fa-copy ml-1"></i>
                </div>
            </div>`;
    });

    userListEl.innerHTML = html;
}

window.copyTextToClipboard = (text, toastMsg) => {
    navigator.clipboard.writeText(text);
    showToast(toastMsg || "Đã sao chép!");
};

window.openUserDetailModal = (uid) => {
    const user = allUsersData.find(u => u.uid === uid);
    if (!user) return;

    selectedUserForModal = user;
    const email = user.email || '';
    const displayName = user.displayName || '';
    const photoUrl = user.photoUrl || '';
    const role = (user.role || '').toLowerCase();
    const isBlocked = user.is_blocked === true;
    const unlocked = Array.isArray(user.unlocked_features) ? user.unlocked_features : [];
    const isPremium = unlocked.includes('premium');
    const anniversaries = Array.isArray(user.anniversaries) ? user.anniversaries : [];

    // Header
    const udEmail = document.getElementById('ud-email');
    const udName = document.getElementById('ud-name');
    const udUid = document.getElementById('ud-uid');
    const udAvatar = document.getElementById('ud-avatar');
    const udEmoji = document.getElementById('ud-emoji');

    if (udEmail) udEmail.textContent = email || 'Tài khoản ẩn danh';
    if (udName) udName.textContent = displayName || 'Chưa cập nhật tên';
    if (udUid) udUid.textContent = `UID: ${uid}`;
    if (udAvatar && photoUrl) udAvatar.src = photoUrl;
    if (udEmoji) udEmoji.textContent = isBlocked ? '🚫' : (role === 'super_admin' ? '👑' : (role === 'admin' ? '🛡️' : (role === 'manager' ? '👔' : '👤')));

    // Section 0: System Roles (Super Admin Only)
    const secSysRole = document.getElementById('sec-sys-role');
    const sysRoleBtns = document.getElementById('sys-role-btns');
    if (secSysRole && sysRoleBtns) {
        if (isSuperAdmin) {
            secSysRole.classList.remove('hidden');
            sysRoleBtns.innerHTML = `
                <button onclick="updateUserRole('${uid}', 'admin')" class="w-full py-2.5 px-2 rounded-xl text-xs font-bold ${role === 'admin' ? 'bg-emerald-600 text-white shadow-lg' : 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/20'} flex items-center justify-center gap-1.5 transition-all">🛡️ Admin</button>
                <button onclick="updateUserRole('${uid}', 'manager')" class="w-full py-2.5 px-2 rounded-xl text-xs font-bold ${role === 'manager' ? 'bg-blue-600 text-white shadow-lg' : 'bg-blue-500/10 text-blue-400 border border-blue-500/30 hover:bg-blue-500/20'} flex items-center justify-center gap-1.5 transition-all">👔 Manager</button>
                <button onclick="updateUserRole('${uid}', 'user')" class="w-full py-2.5 px-2 rounded-xl text-xs font-bold ${role === 'user' || !role ? 'bg-gray-600 text-white' : 'bg-gray-100 dark:bg-white/5 text-gray-400 border border-gray-300 dark:border-white/10 hover:bg-gray-200'} flex items-center justify-center gap-1.5 transition-all">👤 Thu hồi vai trò</button>
            `;
        } else {
            secSysRole.classList.add('hidden');
        }
    }

    // Section 1: VIP Premium Grant
    const udPremBtns = document.getElementById('ud-premium-btns');
    const udPremBanner = document.getElementById('ud-premium-status-banner');

    if (udPremBtns) {
        if (isManager) {
            if (isPremium) {
                if (udPremBanner) udPremBanner.classList.remove('hidden');
                udPremBtns.className = 'grid grid-cols-1 gap-2.5';
                udPremBtns.innerHTML = `<button disabled class="w-full py-2.5 px-3 rounded-xl text-xs font-bold bg-gray-400 text-white opacity-50 cursor-not-allowed flex items-center justify-center gap-1.5"><i class="fa-solid fa-ban"></i> Đã có VIP (Chỉ cấp 1 lần)</button>`;
            } else {
                if (udPremBanner) udPremBanner.classList.add('hidden');
                udPremBtns.className = 'grid grid-cols-1 gap-2.5';
                udPremBtns.innerHTML = `<button onclick="grantUserPremium('${uid}', 30)" class="w-full py-2.5 px-3 rounded-xl text-xs font-bold bg-amber-500 hover:bg-amber-600 text-white shadow-lg flex items-center justify-center gap-1.5 transition-all"><i class="fa-solid fa-gift"></i> Cấp 30 Ngày VIP Premium</button>`;
            }
        } else {
            if (udPremBanner) udPremBanner.classList.add('hidden');
            udPremBtns.className = isPremium ? 'grid grid-cols-2 sm:grid-cols-4 gap-2.5' : 'grid grid-cols-3 gap-2.5';
            udPremBtns.innerHTML = `
                <button onclick="grantUserPremium('${uid}', 30)" class="w-full py-2.5 px-2 rounded-xl text-xs font-bold bg-amber-500 hover:bg-amber-600 text-white shadow-md transition-all flex items-center justify-center gap-1.5"><i class="fa-solid fa-calendar-plus"></i> +30 Ngày</button>
                <button onclick="grantUserPremium('${uid}', 365)" class="w-full py-2.5 px-2 rounded-xl text-xs font-bold bg-amber-600 hover:bg-amber-700 text-white shadow-md transition-all flex items-center justify-center gap-1.5"><i class="fa-solid fa-crown"></i> +1 Năm</button>
                <button onclick="grantUserPremium('${uid}', -1)" class="w-full py-2.5 px-2 rounded-xl text-xs font-bold bg-purple-600 hover:bg-purple-700 text-white shadow-md transition-all flex items-center justify-center gap-1.5"><i class="fa-solid fa-infinity"></i> Vĩnh Viễn</button>
                ${isPremium ? `<button onclick="revokeUserPremium('${uid}')" class="w-full py-2.5 px-2 rounded-xl text-xs font-bold bg-red-500/20 hover:bg-red-500/30 text-red-400 border border-red-500/40 transition-all flex items-center justify-center gap-1.5"><i class="fa-solid fa-trash-can"></i> Hủy VIP</button>` : ''}
            `;
        }
    }

    // Section 2: Account Block Toggle
    const secBlockUser = document.getElementById('sec-block-user');
    const udBlockSwitch = document.getElementById('ud-block-switch');
    const udBlockDesc = document.getElementById('ud-block-desc');

    if (secBlockUser) {
        if (isManager) {
            secBlockUser.classList.add('hidden');
        } else {
            secBlockUser.classList.remove('hidden');
            if (udBlockSwitch) {
                udBlockSwitch.checked = isBlocked;
                udBlockSwitch.onchange = (e) => toggleUserBlockStatus(uid, e.target.checked);
            }
            if (udBlockDesc) udBlockDesc.textContent = isBlocked ? 'Tài khoản đang bị KHÓA truy cập' : 'Tài khoản hoạt động bình thường';
        }
    }

    // Section 3: Background Effects Unlock Manager
    const udEffectsGrid = document.getElementById('ud-effects-grid');
    if (udEffectsGrid) {
        let effHtml = '';
        Object.keys(EFFECT_NAMES_VI).forEach(effId => {
            const isUnlocked = unlocked.includes(effId);
            effHtml += `
                <button onclick="toggleUserEffect('${uid}', '${effId}', ${!isUnlocked})" class="w-full py-2 px-2 rounded-xl text-xs font-semibold ${isUnlocked ? 'bg-violet-600 text-white shadow-sm' : 'bg-gray-100 dark:bg-white/5 text-gray-500 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-white/10'} border border-transparent transition-all flex items-center justify-center gap-1.5 truncate" title="${EFFECT_NAMES_VI[effId]}">
                    <i class="fa-solid ${isUnlocked ? 'fa-check-circle' : 'fa-circle-plus'} text-[11px] shrink-0"></i>
                    <span class="truncate">${EFFECT_NAMES_VI[effId]}</span>
                </button>`;
        });
        udEffectsGrid.innerHTML = effHtml;
    }

    // Section 4: Synced Anniversaries
    const udAnnCount = document.getElementById('ud-ann-count');
    const udAnnList = document.getElementById('ud-ann-list');

    if (udAnnCount) udAnnCount.textContent = anniversaries.length;
    if (udAnnList) {
        if (anniversaries.length === 0) {
            udAnnList.innerHTML = `<p class="text-xs text-gray-400 italic">Chưa có sự kiện nào được sao lưu đồng bộ.</p>`;
        } else {
            let annHtml = '';
            anniversaries.forEach(item => {
                const title = item.title || item.titleVi || 'Sự kiện';
                const dateStr = item.date || item.targetDate || '';
                annHtml += `
                    <div class="p-2.5 rounded-xl bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 flex items-center justify-between text-xs">
                        <span class="font-semibold text-gray-800 dark:text-gray-200 truncate"><i class="fa-solid fa-heart text-pink-500 mr-1.5"></i>${title}</span>
                        <span class="font-mono text-gray-400 shrink-0">${dateStr}</span>
                    </div>`;
            });
            udAnnList.innerHTML = annHtml;
        }
    }

    // Show modal
    if (userDetailModal) {
        userDetailModal.classList.remove('hidden');
        setTimeout(() => userDetailModal.querySelector('.modal-content')?.classList.replace('scale-95', 'scale-100'), 10);
        setTimeout(() => userDetailModal.querySelector('.modal-content')?.classList.replace('opacity-0', 'opacity-100'), 10);
    }
};

window.closeUserDetailModalFunc = () => {
    if (!userDetailModal) return;
    const content = userDetailModal.querySelector('.modal-content');
    if (content) {
        content.classList.replace('scale-100', 'scale-95');
        content.classList.replace('opacity-100', 'opacity-0');
    }
    setTimeout(() => {
        userDetailModal.classList.add('hidden');
    }, 300);
};

if (userDetailModal) {
    userDetailModal.querySelectorAll('.close-modal').forEach(btn => {
        btn.addEventListener('click', window.closeUserDetailModalFunc);
    });
    userDetailModal.addEventListener('click', (e) => {
        if (e.target === userDetailModal) window.closeUserDetailModalFunc();
    });
}

window.updateUserRole = async (uid, newRole) => {
    if (!isSuperAdmin) {
        showToast("Chỉ Super Admin mới có quyền phân vai trò!", true);
        return;
    }
    if (newRole === 'super_admin') {
        showToast("Không được phép cấp quyền Super Admin!", true);
        return;
    }
    try {
        await db.collection('users').doc(uid).set({ role: newRole }, { merge: true });
        showToast(`Đã phân vai trò: ${newRole.toUpperCase()}`);
        openUserDetailModal(uid);
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật vai trò", true);
    }
};

window.grantUserPremium = async (uid, days) => {
    try {
        const user = allUsersData.find(u => u.uid === uid);
        let unlocked = Array.isArray(user?.unlocked_features) ? [...user.unlocked_features] : [];
        if (!unlocked.includes('premium')) unlocked.push('premium');

        const updateData = { unlocked_features: unlocked };

        if (days > 0) {
            const expDate = new Date();
            expDate.setDate(expDate.getDate() + days);
            updateData['expirations.premium'] = firebase.firestore.Timestamp.fromDate(expDate);
        } else if (days < 0) {
            updateData['expirations.premium'] = null; // Lifetime
        }

        await db.collection('users').doc(uid).update(updateData);
        showToast("Cấp VIP Premium thành công!");
        openUserDetailModal(uid);
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cấp VIP Premium", true);
    }
};

window.revokeUserPremium = async (uid) => {
    try {
        const user = allUsersData.find(u => u.uid === uid);
        let unlocked = Array.isArray(user?.unlocked_features) ? user.unlocked_features.filter(x => x !== 'premium') : [];
        await db.collection('users').doc(uid).update({
            unlocked_features: unlocked,
            'expirations.premium': firebase.firestore.FieldValue.delete()
        });
        showToast("Đã hủy quyền VIP Premium!");
        openUserDetailModal(uid);
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi hủy VIP Premium", true);
    }
};

window.toggleUserBlockStatus = async (uid, shouldBlock) => {
    try {
        await db.collection('users').doc(uid).set({ is_blocked: shouldBlock }, { merge: true });
        showToast(shouldBlock ? "Đã KHÓA tài khoản người dùng!" : "Đã MỞ KHÓA tài khoản người dùng!");
        openUserDetailModal(uid);
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật trạng thái khóa", true);
    }
};

window.toggleUserEffect = async (uid, effectId, unlock) => {
    try {
        const user = allUsersData.find(u => u.uid === uid);
        let unlocked = Array.isArray(user?.unlocked_features) ? [...user.unlocked_features] : [];
        if (unlock) {
            if (!unlocked.includes(effectId)) unlocked.push(effectId);
        } else {
            unlocked = unlocked.filter(x => x !== effectId);
        }

        await db.collection('users').doc(uid).update({ unlocked_features: unlocked });
        showToast(unlock ? `Đã mở hiệu ứng ${EFFECT_NAMES_VI[effectId] || effectId}` : `Đã khóa hiệu ứng ${EFFECT_NAMES_VI[effectId] || effectId}`);
        openUserDetailModal(uid);
    } catch (e) {
        console.error(e);
        showToast("Lỗi khi cập nhật hiệu ứng", true);
    }
};
