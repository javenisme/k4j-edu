<script>
	import { browser } from '$app/environment';
	import { base } from '$app/paths';
	import Login from '$lib/components/Login.svelte';
	import Signup from '$lib/components/Signup.svelte';
	import UserDashboard from '$lib/components/UserDashboard.svelte';
	import { user } from '$lib/stores/userStore';
	import { onMount, onDestroy } from 'svelte';
	import { _, locale } from '$lib/i18n';
	import { apiFetch } from '$lib/services/apiClient';
	import { getMyProfile } from '$lib/services/adminService';
	import { clearCurrentSession } from '$lib/session/sessionManager';
	import { renderMarkdownSafe } from '$lib/utils/sanitize';

	let isMounted = true;
	let newsLoadId = 0;
	onDestroy(() => {
		isMounted = false;
	});

	/** @type {any} */
	let config = $state(null);
	let authMode = $state('login');
	/** @type {'overview' | 'dashboard' | 'news'} */
	let currentTab = $state('overview');

	/** @type {any} */
	let profileData = $state(null);
	let isLoadingProfile = $state(false);
	/** @type {string | null} */
	let profileError = $state(null);

	let newsContent = $state('');
	let isLoadingNews = $state(true);

	const visionCards = [
		{
			icon: '✦',
			hebrew: 'מַלְכוּת',
			title: '國度觀',
			copy: '人生以擴展基督國度為標竿。跨越文化、種族、宗派，撒天國的網捕各色各樣的魚。'
		},
		{
			icon: '⏳',
			hebrew: 'קֵץ הַיָּמִים',
			title: '末世觀',
			copy: '末世時鐘正以加速度擺動。但以理預言第 70 個七即將臨近，預備已迫在眉睫。'
		},
		{
			icon: '⚔',
			hebrew: 'חָלוּץ',
			title: '先鋒性',
			copy: '成為呼喊「新郎來了！」的先鋒。喚醒、警惕、預備基督的新婦迎接新郎。'
		},
		{
			icon: '📜',
			hebrew: 'אֱמֶת',
			title: '真理性',
			copy: '透過研讀聖經預言，比較時代徵兆，明白神對末世的旨意。'
		}
	];

	const systemFeatures = [
		{
			href: `${base}/assistants`,
			code: '01',
			title: 'Learning Assistants',
			copy: '建立、測試與發布課程專屬 AI 學習助手。'
		},
		{
			href: `${base}/knowledgebases`,
			code: '02',
			title: 'Knowledge Bases',
			copy: '管理教材、經文、PDF、Markdown 與語義檢索資料。'
		},
		{
			href: `${base}/agent`,
			code: '03',
			title: 'Agent Studio',
			copy: '用代理工作流輔助教師設計、調試和運行教學任務。'
		},
		{
			href: `${base}/evaluaitor`,
			code: '04',
			title: 'Rubrics',
			copy: '設計評估規準，支持學習成果檢核與 AI 輔助評量。'
		},
		{
			href: `${base}/libraries`,
			code: '05',
			title: 'Libraries',
			copy: '沉澱課程資料、文章與可追溯的學習資源庫。'
		}
	];

	const courseCards = [
		[
			'CORE · 01',
			'末世聖經預言研究',
			'End-Times Biblical Prophecy',
			'但以理書、啟示錄、馬太福音 24-25 章、帖撒羅尼迦前後書深度研讀。'
		],
		[
			'CORE · 02',
			'時代徵兆與先鋒洞察',
			'Signs of the Times',
			'以色列復國、地緣政治、科技異變、自然災變、信仰大背道。'
		],
		[
			'CORE · 03',
			'彌賽亞神學與國度觀',
			'Messianic Theology',
			'希伯來根源神學、彌賽亞服事七十週、千禧年國度與新天新地。'
		],
		[
			'CORE · 04',
			'先鋒實戰與多媒體事工',
			'Pioneer Practical Ministry',
			'讀經圖書館應用、影視製作、翻譯實戰、末世特會策劃與事工網絡建立。'
		]
	];

	const manifestoPillars = [
		['קוֹל', '— I —', '呼喊者', '如曠野中施洗約翰的聲音，為主預備道路'],
		['שׁוֹמֵר', '— II —', '守望者', '在城牆上日夜不歇，警報臨到的徵兆'],
		['חוֹקֵר', '— III —', '研究者', '深入聖經預言，比較時代徵兆與經文'],
		['מוֹרֶה', '— IV —', '裝備者', '翻譯西方學者研究，製作多媒體信息']
	];

	const techCards = [
		['01', '經文檢索增強', '上傳聖經、希伯來月曆、神學著作，AI 自動建立語義向量知識庫。'],
		['02', '學科專精導師', '每門課配置專屬 AI 助教，回答基於原典並標註出處。'],
		['03', '隱私至上架構', '可在機構自有算力上運行開源模型，保留完整數據主權。'],
		['04', '多模型一鍵切換', 'OpenAI、Ollama、自託管模型統一接入，教師按任務選擇模型。'],
		['05', '教師無代碼工坊', '視覺化構建、測試、調試與發布教學機器人。'],
		['06', '開放教學標準', '遵循 LTI 標準，連接 Moodle、Canvas 與自有 LMS。']
	];

	$effect(() => {
		if (browser && window.LAMB_CONFIG) {
			config = window.LAMB_CONFIG;
		}
	});

	async function loadProfile() {
		if (!$user.isLoggedIn || !$user.token) return;

		try {
			isLoadingProfile = true;
			profileError = null;
			const data = await getMyProfile($user.token);
			if (!isMounted) return;
			profileData = data;
		} catch (error) {
			if (!isMounted) return;
			if (error instanceof Error && error.message.startsWith('Session expired')) return;
			console.error('Error loading profile:', error);
			profileError = error instanceof Error ? error.message : 'Failed to load profile';
			profileData = null;
		} finally {
			if (isMounted) isLoadingProfile = false;
		}
	}

	async function loadNews() {
		if (!$user.isLoggedIn) {
			isLoadingNews = false;
			return;
		}

		const myLoadId = ++newsLoadId;
		isLoadingNews = true;

		try {
			const currentLang = $locale || 'en';
			const response = await apiFetch(`news/${currentLang}`, {
				headers: { 'Content-Type': 'application/json' }
			});

			if (!isMounted || myLoadId !== newsLoadId) return;

			if (response.ok) {
				const data = await response.json();
				if (!isMounted || myLoadId !== newsLoadId) return;
				newsContent = data.success && data.content?.trim() ? renderMarkdownSafe(data.content) : '';
			} else if (response.status === 404) {
				const fallbackResponse = await apiFetch('news/en', {
					headers: { 'Content-Type': 'application/json' }
				});

				if (!isMounted || myLoadId !== newsLoadId) return;

				if (fallbackResponse.ok) {
					const fallbackData = await fallbackResponse.json();
					if (!isMounted || myLoadId !== newsLoadId) return;
					newsContent =
						fallbackData.success && fallbackData.content?.trim()
							? renderMarkdownSafe(fallbackData.content)
							: '';
				} else {
					newsContent = '';
				}
			} else if (response.status === 503) {
				try {
					const cacheData = await response.json();
					if (!isMounted || myLoadId !== newsLoadId) return;
					newsContent = cacheData.success && cacheData.content ? renderMarkdownSafe(cacheData.content) : '';
				} catch (e) {
					if (!isMounted || myLoadId !== newsLoadId) return;
					newsContent = '';
				}
			} else {
				newsContent = '';
			}
		} catch (error) {
			if (!isMounted || myLoadId !== newsLoadId) return;
			if (error instanceof Error && error.message.startsWith('Session expired')) return;
			newsContent = '';
			console.error('Error fetching news:', error);
		} finally {
			if (isMounted && myLoadId === newsLoadId) isLoadingNews = false;
		}
	}

	onMount(() => {
		if ($user.isLoggedIn) {
			loadProfile();
			loadNews();
		}
	});

	$effect(() => {
		if ($locale && $user.isLoggedIn) {
			loadNews();
		}
	});

	function showLogin() {
		authMode = 'login';
	}

	function showSignup() {
		authMode = 'signup';
	}

	function logout() {
		clearCurrentSession();
		if (browser) {
			window.location.href = base + '/';
		}
	}
</script>

<svelte:head>
	<title>K4J Seminary Portal · LAMB</title>
	<meta
		name="description"
		content="K4J Seminary portal powered by LAMB: learning assistants, knowledge bases, AI study tools, login and registration."
	/>
</svelte:head>

<div class="k4j-portal">
	<div class="grid-bg"></div>
	<div class="star-field"></div>

	<nav class="seminary-nav" aria-label="K4J Seminary sections">
		<a href="{base}/" class="seminary-logo">
			<img src="{base}/img/logo-website-k4j.png" alt="Kingdom for Jesus · 末世先鋒" />
			<span class="logo-divider"></span>
			<span>
				<strong>SEMINARY</strong>
				<small>神學院</small>
			</span>
		</a>
		<div class="seminary-links">
			{#if $user.isLoggedIn}
				<a href="{base}/assistants">Assistants</a>
				<a href="{base}/knowledgebases">Knowledge Bases</a>
				<a href="{base}/agent">Agent Studio</a>
				<a href="{base}/libraries">Libraries</a>
			{:else}
				<a href="#vision">異象</a>
				<a href="#pioneer">先鋒</a>
				<a href="#curriculum">課程</a>
				<a href="#technology">科技</a>
				<a href="#join">加入</a>
			{/if}
		</div>
		<div class="seminary-actions">
			{#if $user.isLoggedIn}
				<span class="seminary-user">{$user.name || $user.email || 'K4J User'}</span>
				<button type="button" class="seminary-cta" onclick={logout}>登出</button>
			{:else}
				<button type="button" class="seminary-cta" onclick={showSignup}>立即申請</button>
			{/if}
		</div>
	</nav>

	{#if $user.isLoggedIn}
		<section class="portal-section authed-hero">
			<div class="portal-shell">
				<div class="eyebrow">K4J Seminary · LAMB Portal</div>
				<div class="authed-heading">
					<div>
						<p class="hebrew">מַלְכוּת לְיֵשׁוּעַ</p>
						<h1>學習與事工工作台</h1>
						<p class="lead">
							{profileData?.user?.name
								? `Welcome back, ${profileData.user.name}.`
								: '管理助手、知識庫、課程資源與 AI 學習活動。'}
						</p>
					</div>
					<div class="status-panel">
						<span>Runtime</span>
						<strong>{config ? 'Configured' : 'Loading'}</strong>
						<small>{config?.api?.baseUrl || '/creator'}</small>
					</div>
				</div>

				<div class="feature-grid embedded-system">
					{#each systemFeatures as item}
						<a class="system-card" href={item.href}>
							<span>{item.code}</span>
							<strong>{item.title}</strong>
							<p>{item.copy}</p>
						</a>
					{/each}
				</div>

				<div class="portal-tabs" role="tablist" aria-label="Portal sections">
					<button type="button" class:active={currentTab === 'overview'} onclick={() => (currentTab = 'overview')}>
						Overview
					</button>
					<button type="button" class:active={currentTab === 'dashboard'} onclick={() => (currentTab = 'dashboard')}>
						Dashboard
					</button>
					<button type="button" class:active={currentTab === 'news'} onclick={() => (currentTab = 'news')}>News</button>
				</div>

				{#if currentTab === 'overview'}
					<div class="overview-grid">
						<div class="portal-card large">
							<div class="label">AI Seminary Engine</div>
							<h2>神學教育 × AI 學習引擎</h2>
							<p>
								每位教師可以建立課程專屬助手，連接教材與知識庫；每位學員可以在受控資料範圍內追問、查證、回看學習歷程。
							</p>
						</div>
						<div class="portal-card">
							<div class="metric">24/7</div>
							<p>AI 神學助教與課程答疑</p>
						</div>
						<div class="portal-card">
							<div class="metric">LTI</div>
							<p>Moodle / Canvas / LMS 教學集成</p>
						</div>
					</div>
				{:else if currentTab === 'dashboard'}
					<div class="dashboard-wrap">
						<UserDashboard
							profile={profileData}
							isLoading={isLoadingProfile}
							error={profileError}
							onRetry={loadProfile}
						/>
					</div>
				{:else}
					<div class="portal-card news-card">
						<div class="label">Help & News</div>
						<h2>{$_('home.help.title', { default: 'Help & News' })}</h2>
						{#if isLoadingNews}
							<p class="muted">{$_('home.help.loadingNews', { default: 'Loading news...' })}</p>
						{:else if newsContent}
							<div class="prose portal-prose max-w-none">
								{@html newsContent}
							</div>
						{:else}
							<p class="muted">{$_('home.help.noNews', { default: 'No news to display.' })}</p>
						{/if}
					</div>
				{/if}
			</div>
		</section>
	{:else}
		<section class="portal-section hero">
			<div class="glow one"></div>
			<div class="glow two"></div>
			<div class="hero-bg-text">מַלְכוּת</div>
			<div class="portal-shell public-layout">
				<div class="hero-copy" id="top">
					<div class="hero-badge">Kingdom for Jesus · Est. 2007</div>
					<h1>
						<span class="hebrew">בָּרוּךְ הַבָּא בְּשֵׁם יְהוָה</span>
						<span class="gold-title">末世先鋒</span><br />
						<span class="school-title">神學院</span>
					</h1>
					<div class="gold-line"></div>
					<p class="tagline">
						為末世末期 · 預備呼喊 <span>「新郎來了！」</span> 的先鋒。<br />
						喚醒 · 警惕 · 預備基督的新婦 · 迎接彌賽亞國度的<span>完全實現</span>。
					</p>
					<p class="verse-line">— 但以理書 9:24-27 · 但以理預言第 70 個七即將臨近 —</p>
					<div class="hero-actions">
						<button type="button" class="btn-primary" onclick={showSignup}>領受呼召 →</button>
						<a class="btn-secondary" href="#vision">瞭解異象</a>
						<button type="button" class="btn-secondary" onclick={showLogin}>進入系統</button>
					</div>
					<div class="hero-stats">
						<div>
							<strong>2007</strong>
							<span>非營利註冊</span>
						</div>
						<div>
							<strong>2011</strong>
							<span>事工啟動</span>
						</div>
						<div>
							<strong>∞</strong>
							<span>華語族群</span>
						</div>
						<div>
							<strong>70</strong>
							<span>但以理預言 · 第 70 個七</span>
						</div>
					</div>
				</div>

				<aside class="auth-panel" aria-label="Authentication">
					<div class="auth-tabs">
						<button type="button" class:active={authMode === 'login'} onclick={showLogin}>Login</button>
						<button type="button" class:active={authMode === 'signup'} onclick={showSignup}>Sign Up</button>
					</div>
					{#if authMode === 'login'}
						<Login on:show-signup={showSignup} />
					{:else}
						<Signup on:show-login={showLogin} />
					{/if}
				</aside>
			</div>
		</section>

		<section class="portal-section compact" id="vision">
			<div class="portal-shell">
				<div class="section-head">
					<div class="label">Vision · 異象</div>
					<h2>
						我們確信 <span class="gold-text">耶穌基督</span> 是 <span class="gold-text italic">彌賽亞</span>。<br />
						我們渴望見祂的國度在地上 <span class="gold-text">擴展</span>。
					</h2>
					<p>
						末世先鋒事工 (Kingdom for Jesus, K4J) 於 2007 年正式註冊為加州及聯邦政府所承認的非營利機構，並於 2011 年正式運作。
						我們服事全世界華語族群，為要持續擴展並實現耶穌的國度。
					</p>
				</div>
				<div class="feature-grid">
					{#each visionCards as item}
						<div class="feature-card vision-card">
							<div class="vision-icon">{item.icon}</div>
							<span class="card-hebrew">{item.hebrew}</span>
							<h3>{item.title}</h3>
							<p>{item.copy}</p>
						</div>
					{/each}
				</div>
				<div class="verse-quote">
					「我們確信耶穌基督是彌賽亞，是君王。<br />
					我們渴望見祂的國度在地上擴展，祂的再來，並祂國度的完全實現。」
					<span>— K4J 末世先鋒事工 · 異象宣言</span>
				</div>
			</div>
		</section>

		<section class="portal-section compact darker" id="pioneer">
			<div class="portal-shell">
				<div class="section-head center">
					<div class="label">The Pioneer Significance</div>
					<h2>為什麼是 <span class="gold-text italic">「先鋒」</span> 神學院？</h2>
				</div>
				<div class="manifesto-banner">
					<div class="manifesto-cry">
						「新郎來了！<br />
						你們出來迎接祂！」
						<span>— 馬太福音 25:6 · 十童女的比喻 —</span>
					</div>
					<p>
						其他神學院培養<span class="gold-text">牧者</span>。我們培養<span class="gold-text">先鋒</span>。<br />
						牧者照顧已在羊圈裡的羊群；先鋒奔走在末世大收割的最前線，喚醒沉睡的新婦。
					</p>
					<div class="pillar-grid">
						{#each manifestoPillars as pillar}
							<div class="pillar">
								<div class="pillar-hebrew">{pillar[0]}</div>
								<div class="pillar-num">{pillar[1]}</div>
								<strong>{pillar[2]}</strong>
								<p>{pillar[3]}</p>
							</div>
						{/each}
					</div>
				</div>
				<div class="difference-grid">
					<div>
						<div class="label">— 與傳統神學院的不同 —</div>
						<h3>時代的迫切性</h3>
						<p>傳統神學院培訓的時間跨度以「世代」計算；我們的呼召以「末日鐘聲」計算。</p>
					</div>
					<div>
						<div class="label">— 跨界的視野 —</div>
						<h3>先鋒的疆界</h3>
						<p>先鋒不被宗派、文化、種族、語言所限，建立超越界限的末世先鋒網絡。</p>
					</div>
					<div>
						<div class="label">— 科技與信仰 —</div>
						<h3>新酒新皮袋</h3>
						<p>當 AI 時代來臨，我們用先進工具裝備這末世最後一代的先鋒。</p>
					</div>
				</div>
			</div>
		</section>

		<section class="portal-section compact" id="curriculum">
			<div class="portal-shell">
				<div class="section-head">
					<div class="label">Curriculum · 課程體系</div>
					<h2>四大核心 · <span class="gold-text italic">末世裝備</span></h2>
					<p>每個課程都對接 K4J 二十年事工沉澱：翻譯西方學者研究、信息匯整、多媒體製作、專題訓練。</p>
				</div>
				<div class="course-grid">
					{#each courseCards as course}
						<div class="course-card">
							<span>{course[0]}</span>
							<h3>{course[1]}</h3>
							<p>{course[2]}</p>
							<small>{course[3]}</small>
						</div>
					{/each}
				</div>
				<div class="resource-strip">
					<div class="label">— Hands-On Resources —</div>
					<p>
						每位學員享有 K4J 全部資源：2025-2026 希伯來月曆 · 彌賽亞服事七十週卷軸 · 「愛以真」音樂會錄影 · 蝗蟲野蜜讀經圖書館。
					</p>
				</div>
			</div>
		</section>

		<section class="portal-section compact darker" id="technology">
			<div class="portal-shell">
				<div class="section-head center">
					<div class="label">Technology · 新酒新皮袋</div>
					<h2>末世先鋒 × <span class="gold-text italic">AI 神學教育</span></h2>
					<p>
						我們不是把舊講道放上 YouTube 就稱為「線上神學院」。我們建立的是為神學量身打造的 AI 學習引擎。
					</p>
				</div>
				<div class="tech-grid">
					{#each techCards as item}
						<div class="tech-card">
							<div class="tech-num">{item[0]}</div>
							<h3>{item[1]}</h3>
							<p>{item[2]}</p>
						</div>
					{/each}
				</div>
				<div class="tech-arch">
					<div><strong>後端引擎</strong><span>FastAPI · 高性能 Python 服務 · 教學助手編排</span></div>
					<div><strong>前端體驗</strong><span>Svelte 5 · 現代化響應式 UI · 移動端優先</span></div>
					<div><strong>知識管道</strong><span>PDF · Word · Markdown · 自動向量化 · 語義檢索</span></div>
					<div><strong>模型網關</strong><span>OpenAI / Ollama / 自託管模型統一路由</span></div>
					<div><strong>教學集成</strong><span>LTI 1.3 · Moodle / Canvas / 自有 LMS</span></div>
				</div>
			</div>
		</section>

		<section class="portal-section compact" id="join">
			<div class="portal-shell">
				<div class="section-head center">
					<div class="label">System · 平台功能</div>
					<h2>嵌入 LAMB 核心工作流</h2>
					<p>登入後即可進入以下功能；未登入時保留入口可見性，幫助新用戶理解系統能力。</p>
				</div>
				<div class="feature-grid embedded-system">
					{#each systemFeatures as item}
						<div class="system-card locked">
							<span>{item.code}</span>
							<strong>{item.title}</strong>
							<p>{item.copy}</p>
						</div>
					{/each}
				</div>
				<div class="join-panel">
					<div class="join-cross">✦</div>
					<div class="label">Apply Now · 領受呼召</div>
					<h2>如果你的心被 <span class="gold-text italic">攪動</span>，那就是呼召。</h2>
					<p>登入或申請註冊，進入 K4J Seminary 的 AI 學習與教學平台。</p>
					<div class="hero-actions centered">
						<button type="button" class="btn-primary" onclick={showSignup}>申請註冊</button>
						<button type="button" class="btn-secondary" onclick={showLogin}>已有帳號登入</button>
					</div>
				</div>
			</div>
		</section>
	{/if}

	<footer class="seminary-footer">
		<div class="portal-shell footer-inner">
			<a href="{base}/" class="footer-brand">
				<img src="{base}/img/logo-website-k4j.png" alt="Kingdom for Jesus" />
				<span>Kingdom for Jesus · K4J Seminary</span>
			</a>
			<div class="footer-meta">
				<span>末世先鋒神學院</span>
				<span>Powered by LAMB</span>
			</div>
			<div class="footer-links">
				<a href="{base}/assistants">Assistants</a>
				<a href="{base}/knowledgebases">Knowledge Bases</a>
				<a href="{base}/agent">Agent Studio</a>
			</div>
		</div>
	</footer>
</div>

<style>
	:global(body) {
		background: #07111f;
	}

	.k4j-portal {
		--void: #07111f;
		--night: #0a1a2e;
		--dusk: #142540;
		--gold: #d4af37;
		--gold-light: #f0d785;
		--ivory: #f4ead5;
		--parchment: #ebd9a9;
		--muted: #c8b68a;
		--dim: #8b7a52;
		--royal: #6b2d5c;
		min-height: calc(100vh - 4rem);
		position: relative;
		overflow: hidden;
		background:
			radial-gradient(circle at 15% 15%, rgba(212, 175, 55, 0.11), transparent 30%),
			radial-gradient(circle at 85% 8%, rgba(107, 45, 92, 0.22), transparent 32%),
			linear-gradient(135deg, var(--void), var(--night) 54%, var(--void));
		color: var(--ivory);
		font-family:
			'Noto Sans SC',
			'Noto Serif SC',
			system-ui,
			sans-serif;
	}

	.grid-bg,
	.star-field {
		position: absolute;
		inset: 0;
		pointer-events: none;
	}

	.grid-bg {
		background-image:
			linear-gradient(rgba(212, 175, 55, 0.03) 1px, transparent 1px),
			linear-gradient(90deg, rgba(212, 175, 55, 0.03) 1px, transparent 1px);
		background-size: 80px 80px;
	}

	.star-field {
		opacity: 0.45;
		background-image:
			radial-gradient(1px 1px at 20% 30%, var(--gold) 100%, transparent),
			radial-gradient(1px 1px at 60% 70%, var(--gold-light) 100%, transparent),
			radial-gradient(1px 1px at 80% 20%, var(--gold) 100%, transparent),
			radial-gradient(2px 2px at 50% 50%, rgba(212, 175, 55, 0.55) 100%, transparent);
		background-size: 560px 560px;
	}

	.portal-section {
		position: relative;
		padding: clamp(56px, 8vw, 120px) clamp(18px, 5vw, 72px);
	}

	.seminary-nav {
		position: sticky;
		top: 0;
		z-index: 20;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 28px;
		padding: 18px clamp(18px, 5vw, 64px);
		border-bottom: 1px solid rgba(212, 175, 55, 0.22);
		background: rgba(7, 17, 31, 0.88);
		backdrop-filter: blur(18px);
	}

	.seminary-logo {
		display: flex;
		align-items: center;
		gap: 16px;
		color: inherit;
		text-decoration: none;
	}

	.seminary-logo img {
		width: 150px;
		height: auto;
		filter: brightness(0) saturate(100%) invert(74%) sepia(58%) saturate(415%) hue-rotate(2deg)
			brightness(91%) contrast(91%);
	}

	.logo-divider {
		width: 1px;
		height: 30px;
		background: linear-gradient(to bottom, transparent, var(--gold), transparent);
		opacity: 0.65;
	}

	.seminary-logo strong,
	.seminary-logo small {
		display: block;
		line-height: 1;
	}

	.seminary-logo strong {
		color: var(--gold);
		font-family: Georgia, serif;
		font-size: 12px;
		letter-spacing: 0.28em;
	}

	.seminary-logo small {
		margin-top: 6px;
		color: var(--dim);
		font-size: 10px;
		letter-spacing: 0.25em;
	}

	.seminary-links {
		display: flex;
		gap: 28px;
	}

	.seminary-links a {
		color: var(--muted);
		font-size: 14px;
		font-weight: 600;
		letter-spacing: 0.06em;
		text-decoration: none;
		transition: color 0.2s ease;
	}

	.seminary-links a:hover {
		color: var(--gold);
	}

	.seminary-actions {
		display: flex;
		align-items: center;
		gap: 14px;
	}

	.seminary-user {
		max-width: 180px;
		overflow: hidden;
		color: var(--muted);
		font-size: 13px;
		font-weight: 700;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.seminary-cta {
		min-height: 40px;
		padding: 0 20px;
		border: 1px solid var(--gold);
		color: var(--gold);
		font-family: Georgia, serif;
		font-size: 12px;
		font-weight: 800;
		letter-spacing: 0.18em;
		background: transparent;
	}

	.portal-section.hero {
		min-height: calc(100vh - 4rem);
		display: flex;
		align-items: center;
	}

	.portal-section.compact {
		padding-top: clamp(64px, 8vw, 110px);
		padding-bottom: clamp(64px, 8vw, 110px);
		background: rgba(7, 17, 31, 0.56);
	}

	.portal-section.darker {
		background: rgba(10, 26, 46, 0.7);
	}

	.portal-shell {
		width: min(1440px, 100%);
		margin: 0 auto;
		position: relative;
		z-index: 1;
	}

	.public-layout {
		display: grid;
		grid-template-columns: minmax(0, 1.3fr) minmax(360px, 0.7fr);
		gap: clamp(32px, 5vw, 72px);
		align-items: center;
	}

	.hero-bg-text {
		position: absolute;
		top: 46%;
		left: 44%;
		transform: translate(-50%, -50%);
		font-family: Georgia, serif;
		font-size: clamp(220px, 28vw, 520px);
		font-weight: 900;
		line-height: 1;
		color: rgba(212, 175, 55, 0.025);
		direction: rtl;
		user-select: none;
		pointer-events: none;
	}

	.glow {
		position: absolute;
		border-radius: 999px;
		filter: blur(70px);
		pointer-events: none;
	}

	.glow.one {
		width: 360px;
		height: 360px;
		left: 8%;
		top: 16%;
		background: rgba(212, 175, 55, 0.16);
	}

	.glow.two {
		width: 440px;
		height: 440px;
		right: 2%;
		bottom: 6%;
		background: rgba(107, 45, 92, 0.28);
	}

	.hero-badge,
	.label,
	.course-card span,
	.feature-card span {
		color: var(--gold);
		font-family: Georgia, 'Times New Roman', serif;
		font-size: 12px;
		font-weight: 700;
		letter-spacing: 0.25em;
		text-transform: uppercase;
	}

	.hero-badge {
		display: inline-flex;
		border: 1px solid rgba(212, 175, 55, 0.72);
		padding: 8px 16px;
		margin-bottom: 28px;
		background: rgba(7, 17, 31, 0.46);
	}

	.hebrew {
		margin: 0 0 12px;
		color: var(--gold);
		font-family: Georgia, serif;
		font-size: clamp(28px, 4vw, 58px);
		font-weight: 700;
		opacity: 0.86;
		direction: rtl;
	}

	h1,
	h2,
	h3 {
		font-family: Georgia, 'Times New Roman', 'Noto Serif SC', serif;
		letter-spacing: 0;
	}

	.hero-copy h1 {
		margin: 0;
		line-height: 1;
		color: var(--ivory);
	}

	.gold-title,
	.school-title {
		font-family: Georgia, 'Times New Roman', 'Noto Serif SC', serif;
		font-weight: 900;
		line-height: 1;
	}

	.gold-title {
		display: inline-block;
		color: var(--gold);
		font-size: clamp(54px, 7vw, 132px);
	}

	.school-title {
		display: inline-block;
		margin-top: 10px;
		color: var(--ivory);
		font-size: clamp(40px, 4.8vw, 88px);
	}

	.gold-line {
		width: 120px;
		height: 2px;
		margin: 34px 0;
		background: linear-gradient(90deg, var(--gold), transparent);
	}

	.tagline,
	.section-head p,
	.portal-card p,
	.feature-card p,
	.system-card p,
	.course-card p,
	.lead,
	.muted {
		color: var(--muted);
		line-height: 1.75;
	}

	.tagline {
		max-width: 780px;
		font-size: clamp(17px, 1.5vw, 22px);
	}

	.tagline span {
		color: var(--gold);
		font-weight: 700;
	}

	.verse-line {
		margin-top: 18px;
		color: var(--dim);
		font-family: Georgia, serif;
		font-size: 12px;
		letter-spacing: 0.2em;
		text-transform: uppercase;
	}

	.hero-actions {
		display: flex;
		flex-wrap: wrap;
		gap: 16px;
		margin-top: 36px;
	}

	.btn-primary,
	.btn-secondary {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		min-height: 48px;
		padding: 0 28px;
		border: 1px solid var(--gold);
		font-family: Georgia, serif;
		font-size: 13px;
		font-weight: 800;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		transition:
			transform 0.2s ease,
			background 0.2s ease,
			color 0.2s ease;
	}

	.btn-primary {
		background: var(--gold);
		color: var(--void);
	}

	.btn-secondary {
		background: transparent;
		color: var(--gold);
		text-decoration: none;
	}

	.btn-primary:hover,
	.btn-secondary:hover {
		transform: translateY(-2px);
	}

	.hero-stats {
		display: flex;
		flex-wrap: wrap;
		gap: 34px;
		margin-top: 56px;
		padding-top: 30px;
		border-top: 1px solid rgba(212, 175, 55, 0.22);
	}

	.hero-stats strong,
	.metric {
		display: block;
		color: var(--gold);
		font-family: Georgia, serif;
		font-size: clamp(28px, 3vw, 48px);
		line-height: 1;
	}

	.hero-stats span {
		display: block;
		margin-top: 8px;
		color: var(--dim);
		font-size: 12px;
		letter-spacing: 0.14em;
		text-transform: uppercase;
	}

	.auth-panel {
		border: 1px solid rgba(212, 175, 55, 0.36);
		background: rgba(244, 234, 213, 0.96);
		box-shadow: 0 24px 90px rgba(0, 0, 0, 0.32);
		color: #111827;
	}

	.auth-panel :global(.max-w-md) {
		max-width: none;
		box-shadow: none;
		border-radius: 0;
		background: transparent;
	}

	.auth-tabs {
		display: grid;
		grid-template-columns: 1fr 1fr;
		border-bottom: 1px solid rgba(20, 37, 64, 0.14);
	}

	.auth-tabs button {
		padding: 14px 16px;
		font-weight: 800;
		color: #475569;
		background: rgba(255, 255, 255, 0.28);
	}

	.auth-tabs button.active {
		color: var(--void);
		background: rgba(212, 175, 55, 0.2);
		box-shadow: inset 0 -2px 0 var(--gold);
	}

	.section-head {
		max-width: 900px;
		margin-bottom: 44px;
	}

	.section-head.center {
		margin-left: auto;
		margin-right: auto;
		text-align: center;
	}

	.section-head h2,
	.portal-card h2 {
		margin: 14px 0 16px;
		color: var(--ivory);
		font-size: clamp(30px, 4vw, 56px);
		line-height: 1.12;
	}

	.gold-text {
		color: var(--gold);
	}

	.italic {
		font-style: italic;
	}

	.feature-grid,
	.course-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
		gap: 22px;
	}

	.feature-card,
	.course-card,
	.system-card,
	.portal-card {
		position: relative;
		border: 1px solid rgba(212, 175, 55, 0.22);
		background: rgba(20, 37, 64, 0.42);
		padding: 28px;
	}

	.feature-card::before,
	.course-card::before,
	.system-card::before {
		content: '';
		position: absolute;
		top: -1px;
		left: -1px;
		width: 14px;
		height: 14px;
		border-top: 2px solid var(--gold);
		border-left: 2px solid var(--gold);
	}

	.feature-card h3,
	.course-card h3,
	.system-card strong {
		display: block;
		margin: 12px 0 10px;
		color: var(--gold);
		font-size: 22px;
	}

	.vision-icon {
		color: var(--gold);
		font-family: Georgia, serif;
		font-size: 34px;
		line-height: 1;
		margin-bottom: 14px;
	}

	.feature-card .card-hebrew {
		display: block;
		margin-bottom: 8px;
		color: rgba(212, 175, 55, 0.75);
		font-family: Georgia, serif;
		font-size: 18px;
		letter-spacing: 0;
		text-transform: none;
		direction: rtl;
	}

	.verse-quote {
		margin-top: 64px;
		padding: 34px;
		border: 1px solid rgba(212, 175, 55, 0.28);
		background: rgba(212, 175, 55, 0.04);
		color: var(--ivory);
		font-family: Georgia, 'Noto Serif SC', serif;
		font-size: clamp(20px, 2vw, 32px);
		font-style: italic;
		line-height: 1.55;
		text-align: center;
	}

	.verse-quote span {
		display: block;
		margin-top: 18px;
		color: var(--dim);
		font-size: 12px;
		font-style: normal;
		letter-spacing: 0.16em;
		text-transform: uppercase;
	}

	.manifesto-banner {
		position: relative;
		padding: clamp(34px, 5vw, 64px);
		border: 1px solid var(--gold);
		background: linear-gradient(135deg, rgba(212, 175, 55, 0.06), rgba(107, 45, 92, 0.08));
		text-align: center;
	}

	.manifesto-banner::before {
		content: '✦  ✦  ✦';
		position: absolute;
		top: -12px;
		left: 50%;
		transform: translateX(-50%);
		padding: 0 18px;
		background: var(--night);
		color: var(--gold);
		font-size: 12px;
		letter-spacing: 0.7em;
	}

	.manifesto-cry {
		color: var(--gold);
		font-family: Georgia, 'Noto Serif SC', serif;
		font-size: clamp(30px, 4vw, 58px);
		font-style: italic;
		font-weight: 700;
		line-height: 1.35;
	}

	.manifesto-cry span {
		display: block;
		margin-top: 20px;
		color: var(--dim);
		font-size: 12px;
		font-style: normal;
		letter-spacing: 0.18em;
		text-transform: uppercase;
	}

	.manifesto-banner > p {
		max-width: 1000px;
		margin: 32px auto 0;
		color: var(--muted);
		font-size: clamp(16px, 1.2vw, 19px);
		line-height: 1.85;
	}

	.pillar-grid,
	.difference-grid,
	.tech-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
		gap: 24px;
	}

	.pillar-grid {
		margin-top: 44px;
	}

	.pillar {
		padding: 22px;
	}

	.pillar-hebrew {
		color: rgba(212, 175, 55, 0.78);
		font-family: Georgia, serif;
		font-size: 18px;
		direction: rtl;
	}

	.pillar-num {
		margin: 10px 0;
		color: var(--gold);
		font-family: Georgia, serif;
		font-size: 13px;
		letter-spacing: 0.18em;
	}

	.pillar strong {
		display: block;
		color: var(--ivory);
		font-family: Georgia, 'Noto Serif SC', serif;
		font-size: 20px;
	}

	.pillar p,
	.difference-grid p,
	.tech-card p,
	.resource-strip p,
	.join-panel p {
		color: var(--muted);
		line-height: 1.7;
	}

	.difference-grid {
		margin-top: 54px;
	}

	.difference-grid h3 {
		margin: 12px 0;
		color: var(--gold);
		font-size: 24px;
	}

	.course-card small {
		display: block;
		margin-top: 16px;
		color: var(--muted);
		line-height: 1.65;
	}

	.resource-strip {
		margin-top: 46px;
		padding: 28px;
		border: 1px solid rgba(212, 175, 55, 0.22);
		background: rgba(212, 175, 55, 0.04);
		text-align: center;
	}

	.tech-card {
		border: 1px solid rgba(212, 175, 55, 0.22);
		background: rgba(20, 37, 64, 0.42);
		padding: 28px;
	}

	.tech-num {
		color: rgba(212, 175, 55, 0.46);
		font-family: Georgia, serif;
		font-size: 44px;
		font-weight: 900;
		line-height: 1;
	}

	.tech-card h3 {
		margin: 14px 0 10px;
		color: var(--gold);
		font-size: 21px;
	}

	.tech-arch {
		margin-top: 46px;
		border: 1px solid var(--gold);
		background: rgba(7, 17, 31, 0.72);
		padding: 28px;
		font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
	}

	.tech-arch div {
		display: grid;
		grid-template-columns: 130px 1fr;
		gap: 20px;
		padding: 12px 0;
		border-bottom: 1px solid rgba(212, 175, 55, 0.12);
	}

	.tech-arch div:last-child {
		border-bottom: 0;
	}

	.tech-arch strong {
		color: var(--gold);
	}

	.tech-arch span {
		color: var(--muted);
	}

	.join-panel {
		margin-top: 64px;
		text-align: center;
	}

	.join-cross {
		color: var(--gold);
		font-family: Georgia, serif;
		font-size: 56px;
		line-height: 1;
		margin-bottom: 18px;
	}

	.join-panel h2 {
		margin: 16px auto;
		max-width: 900px;
		color: var(--ivory);
		font-size: clamp(32px, 5vw, 72px);
		line-height: 1.12;
	}

	.centered {
		justify-content: center;
	}

	.system-card {
		text-decoration: none;
		color: inherit;
		transition:
			transform 0.2s ease,
			border-color 0.2s ease,
			background 0.2s ease;
	}

	.system-card:hover {
		transform: translateY(-3px);
		border-color: var(--gold);
		background: rgba(212, 175, 55, 0.07);
	}

	.system-card span {
		color: rgba(212, 175, 55, 0.46);
		font-family: Georgia, serif;
		font-size: 42px;
		font-weight: 900;
		line-height: 1;
	}

	.system-card.locked {
		opacity: 0.88;
	}

	.authed-hero {
		min-height: calc(100vh - 4rem);
		background: rgba(7, 17, 31, 0.38);
	}

	.eyebrow {
		margin-bottom: 18px;
		color: var(--gold);
		font-size: 12px;
		font-weight: 800;
		letter-spacing: 0.22em;
		text-transform: uppercase;
	}

	.authed-heading {
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 24px;
		align-items: end;
		margin-bottom: 30px;
	}

	.authed-heading h1 {
		margin: 0;
		font-size: clamp(38px, 5vw, 72px);
		line-height: 1.05;
	}

	.status-panel {
		min-width: 220px;
		border: 1px solid rgba(212, 175, 55, 0.26);
		background: rgba(20, 37, 64, 0.5);
		padding: 18px;
	}

	.status-panel span,
	.status-panel small {
		display: block;
		color: var(--dim);
		font-size: 12px;
	}

	.status-panel strong {
		display: block;
		margin: 4px 0;
		color: var(--gold);
		font-size: 22px;
	}

	.portal-tabs {
		display: flex;
		flex-wrap: wrap;
		gap: 10px;
		margin: 34px 0 24px;
		border-bottom: 1px solid rgba(212, 175, 55, 0.2);
	}

	.portal-tabs button {
		padding: 12px 18px;
		color: var(--muted);
		border: 1px solid transparent;
		border-bottom: 0;
		font-weight: 800;
	}

	.portal-tabs button.active {
		color: var(--void);
		background: var(--gold);
		border-color: var(--gold);
	}

	.overview-grid {
		display: grid;
		grid-template-columns: 2fr 1fr 1fr;
		gap: 20px;
	}

	.portal-card.large {
		grid-row: span 2;
	}

	.news-card {
		min-height: 260px;
	}

	.dashboard-wrap {
		background: #f8fafc;
		color: #111827;
		border-radius: 0;
		padding: clamp(18px, 3vw, 32px);
	}

	.portal-prose {
		color: var(--ivory);
	}

	.portal-prose :global(a) {
		color: var(--gold);
	}

	.seminary-footer {
		position: relative;
		z-index: 1;
		border-top: 1px solid rgba(212, 175, 55, 0.22);
		background: rgba(7, 17, 31, 0.9);
		padding: 28px clamp(18px, 5vw, 64px);
	}

	.footer-inner {
		display: grid;
		grid-template-columns: minmax(220px, 1.2fr) minmax(180px, auto) minmax(260px, 1fr);
		gap: 24px;
		align-items: center;
	}

	.footer-brand {
		display: inline-flex;
		align-items: center;
		gap: 14px;
		color: var(--gold);
		font-family: Georgia, 'Times New Roman', serif;
		font-size: 13px;
		font-weight: 800;
		letter-spacing: 0.08em;
		text-decoration: none;
	}

	.footer-brand img {
		width: 126px;
		height: auto;
		filter: brightness(0) saturate(100%) invert(74%) sepia(58%) saturate(415%) hue-rotate(2deg)
			brightness(91%) contrast(91%);
	}

	.footer-meta {
		display: grid;
		gap: 6px;
		color: var(--dim);
		font-size: 12px;
		font-weight: 700;
		letter-spacing: 0.1em;
		text-align: center;
		text-transform: uppercase;
	}

	.footer-links {
		display: flex;
		flex-wrap: wrap;
		justify-content: flex-end;
		gap: 16px;
	}

	.footer-links a {
		color: var(--muted);
		font-size: 13px;
		font-weight: 700;
		text-decoration: none;
	}

	.footer-links a:hover {
		color: var(--gold);
	}

	@media (max-width: 980px) {
		.public-layout,
		.authed-heading,
		.overview-grid,
		.footer-inner {
			grid-template-columns: 1fr;
		}

		.seminary-links {
			display: none;
		}

		.footer-meta {
			text-align: left;
		}

		.footer-links {
			justify-content: flex-start;
		}

		.auth-panel {
			max-width: 560px;
		}
	}

	@media (max-width: 640px) {
		.portal-section {
			padding-left: 16px;
			padding-right: 16px;
		}

		.hero-copy h1 {
			font-size: 48px;
		}

		.seminary-nav {
			position: relative;
			align-items: flex-start;
			flex-wrap: wrap;
		}

		.seminary-logo img {
			width: 128px;
		}

		.seminary-actions {
			width: 100%;
			justify-content: space-between;
		}

		.seminary-user {
			max-width: min(260px, 52vw);
		}

		.footer-brand {
			align-items: flex-start;
			flex-direction: column;
		}

		.hero-actions,
		.hero-stats {
			flex-direction: column;
		}

		.btn-primary,
		.btn-secondary {
			width: 100%;
			justify-content: center;
		}

		.feature-card,
		.course-card,
		.system-card,
		.portal-card {
			padding: 22px;
		}
	}
</style>
