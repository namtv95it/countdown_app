document.addEventListener('DOMContentLoaded', () => {
    let pathname = window.location.pathname;
    let eventId = pathname.substring(pathname.lastIndexOf('/') + 1).replace('.html', '');

    const event = specialOccasions.find(occ => occ.id === eventId);
    
    if (!event) {
        document.getElementById('event-title').innerText = 'Không tìm thấy sự kiện';
        document.getElementById('event-banner').style.display = 'none';
        document.getElementById('empty-state').classList.remove('hidden');
        document.getElementById('empty-state').classList.add('flex');
        return;
    }

    // Cập nhật thông tin sự kiện
    document.title = event.name + ' - Gợi Ý Quà Tặng';
    document.getElementById('event-title').innerText = event.name;
    document.getElementById('event-emoji').innerText = event.emoji;
    document.getElementById('event-name').innerText = event.name;
    document.getElementById('event-date').innerText = event.dateLabel;
    
    // Cập nhật banner background
    document.getElementById('event-banner').style.background = event.gradient;

    // Tính toán số ngày
    const daysLeft = daysUntil(event.month, event.day);

    // Tính toán Next / Prev Sự kiện
    const upcomingOccasions = specialOccasions
        .map(occ => ({ ...occ, daysLeft: daysUntil(occ.month, occ.day) }))
        .sort((a, b) => a.daysLeft - b.daysLeft);

    const currentIndex = upcomingOccasions.findIndex(occ => occ.id === event.id);
    let prevEventId = null;
    let nextEventId = null;

    if (currentIndex !== -1) {
        prevEventId = currentIndex > 0 
            ? upcomingOccasions[currentIndex - 1].id 
            : upcomingOccasions[upcomingOccasions.length - 1].id;
            
        nextEventId = currentIndex < upcomingOccasions.length - 1 
            ? upcomingOccasions[currentIndex + 1].id 
            : upcomingOccasions[0].id;
    }

    // Thêm nút Next / Prev vào Header
    const headerContainer = document.querySelector('#event-header .container');
    if (headerContainer && nextEventId && prevEventId) {
        const spacer = headerContainer.lastElementChild;
        if (spacer && spacer.tagName === 'DIV') {
            spacer.className = "flex items-center gap-2 justify-end min-w-[72px]";
            spacer.innerHTML = `
                <a href="${prevEventId}.html" class="w-8 h-8 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 transition text-white" title="Sự kiện trước">
                    <i class="fa-solid fa-angle-left"></i>
                </a>
                <a href="${nextEventId}.html" class="w-8 h-8 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 transition text-white" title="Sự kiện tiếp theo">
                    <i class="fa-solid fa-angle-right"></i>
                </a>
            `;
            
            // Điều chỉnh nút back bên trái để tiêu đề ở giữa không bị lệch
            const leftBtn = headerContainer.firstElementChild;
            if (leftBtn && leftBtn.tagName === 'BUTTON') {
                leftBtn.onclick = () => { window.location.href = 'index.html'; };
                leftBtn.innerHTML = '<i class="fa-solid fa-house"></i>';
                
                const leftWrapper = document.createElement('div');
                leftWrapper.className = "min-w-[72px] flex items-center justify-start";
                leftBtn.parentNode.insertBefore(leftWrapper, leftBtn);
                leftWrapper.appendChild(leftBtn);
            }
        }
    }
    
    const countdownText = document.getElementById('event-countdown-text');
    if (daysLeft === 0) {
        countdownText.innerText = '🎉 Hôm nay là ngày lễ!';
    } else {
        countdownText.innerText = `Chỉ còn ${daysLeft} ngày nữa`;
    }

    // Lọc sản phẩm theo danh mục của sự kiện
    const eventProducts = products.filter(p => p.categoryId === event.categoryId);
    
    document.getElementById('product-count').innerText = `${eventProducts.length} món`;

    const grid = document.getElementById('product-grid');
    const emptyState = document.getElementById('empty-state');
    grid.innerHTML = '';

    if (eventProducts.length === 0) {
        grid.style.display = 'none';
        emptyState.classList.remove('hidden');
        emptyState.classList.add('flex');
    } else {
        grid.style.display = 'grid';
        emptyState.classList.add('hidden');
        emptyState.classList.remove('flex');

        eventProducts.forEach(product => {
            const card = document.createElement('a');
            card.href = product.affiliateUrl;
            card.target = '_blank';
            card.className = 'bg-darkSurface rounded-2xl overflow-hidden border border-white/5 active:scale-95 transition-transform block relative';

            if (product.isPopular) {
                card.innerHTML += `<div class="absolute top-2 left-2 bg-brandPink text-white text-[10px] font-bold px-2 py-0.5 rounded-full z-10 shadow-lg">HOT</div>`;
            }

            card.innerHTML += `
                <div class="aspect-square bg-white/5 overflow-hidden">
                    <img src="${product.imageUrl}" alt="${product.name}" class="w-full h-full object-cover">
                </div>
                <div class="p-3">
                    <h3 class="font-bold text-sm mb-1 leading-tight line-clamp-2">${product.name}</h3>
                    <p class="text-[10px] text-white/50 mb-2 line-clamp-2 leading-snug">${product.description}</p>
                    <div class="flex items-center justify-between">
                        <span class="text-brandYellow font-extrabold text-sm">${product.priceRange}</span>
                        <div class="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center">
                            <i class="fa-solid fa-cart-shopping text-[10px]"></i>
                        </div>
                    </div>
                </div>
            `;
            grid.appendChild(card);
        });
    }
});
