import os
import sys
import shutil
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_header_footer(num_pages)
            super().showPage()
        super().save()

    def draw_header_footer(self, page_count):
        if self._pageNumber == 1:
            return  # Suppress running header/footer on cover page

        self.saveState()
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#475569"))

        # Running Header
        header_text = "RECIPE APP - CODEBASE DOCUMENTATION & VIVA HANDBOOK"
        student_text = "SOURAV DEBNATH | 22CSE009"
        self.drawString(54, 750, header_text)
        self.drawRightString(612 - 54, 750, student_text)
        
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.75)
        self.line(54, 742, 612 - 54, 742)

        # Running Footer
        self.line(54, 48, 612 - 54, 48)
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(54, 34, "Mobile Application Development Lab Final Exam & Viva Preparation Manual")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(612 - 54, 34, page_str)
        self.restoreState()


def build_pdf(filename):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    base_styles = getSampleStyleSheet()
    styles = {}

    styles['CoverTitle'] = ParagraphStyle(
        'CoverTitle',
        parent=base_styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=30,
        textColor=colors.HexColor("#FFFFFF"),
        alignment=1,
        spaceAfter=10
    )

    styles['CoverSubtitle'] = ParagraphStyle(
        'CoverSubtitle',
        parent=base_styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#FF8A65"),
        alignment=1,
        spaceAfter=12
    )

    styles['CoverDesc'] = ParagraphStyle(
        'CoverDesc',
        parent=base_styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14.5,
        textColor=colors.HexColor("#E2E8F0"),
        alignment=1,
        spaceAfter=8
    )

    styles['CoverMetaLabel'] = ParagraphStyle(
        'CoverMetaLabel',
        parent=base_styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#0F172A")
    )

    styles['CoverMetaVal'] = ParagraphStyle(
        'CoverMetaVal',
        parent=base_styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#334155")
    )

    styles['H1'] = ParagraphStyle(
        'H1',
        parent=base_styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=13.5,
        leading=17.5,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True
    )

    styles['H2'] = ParagraphStyle(
        'H2',
        parent=base_styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=14.5,
        textColor=colors.HexColor("#C2410C"),
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    styles['H3'] = ParagraphStyle(
        'H3',
        parent=base_styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12.5,
        textColor=colors.HexColor("#1E293B"),
        spaceBefore=6,
        spaceAfter=3,
        keepWithNext=True
    )

    styles['Body'] = ParagraphStyle(
        'Body',
        parent=base_styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=colors.HexColor("#334155"),
        spaceAfter=5
    )

    styles['BodyBold'] = ParagraphStyle(
        'BodyBold',
        parent=styles['Body'],
        fontName='Helvetica-Bold',
        textColor=colors.HexColor("#0F172A")
    )

    styles['Bullet'] = ParagraphStyle(
        'Bullet',
        parent=styles['Body'],
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=3
    )

    styles['CodeBlock'] = ParagraphStyle(
        'CodeBlock',
        parent=base_styles['Normal'],
        fontName='Courier',
        fontSize=7.2,
        leading=9.8,
        textColor=colors.HexColor("#0F172A"),
        backColor=colors.HexColor("#F8FAFC"),
        borderColor=colors.HexColor("#CBD5E1"),
        borderWidth=0.5,
        borderPadding=6,
        spaceBefore=4,
        spaceAfter=6,
        keepWithNext=False
    )

    styles['Callout'] = ParagraphStyle(
        'Callout',
        parent=base_styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=12,
        textColor=colors.HexColor("#1E293B"),
        backColor=colors.HexColor("#FFF7ED"),
        borderColor=colors.HexColor("#FDBA74"),
        borderWidth=1,
        borderPadding=6,
        spaceBefore=5,
        spaceAfter=6
    )

    styles['TableHead'] = ParagraphStyle(
        'TableHead',
        parent=base_styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=10.5,
        textColor=colors.HexColor("#FFFFFF"),
        alignment=0
    )

    styles['TableCell'] = ParagraphStyle(
        'TableCell',
        parent=base_styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=10.5,
        textColor=colors.HexColor("#1E293B")
    )

    styles['TableCellBold'] = ParagraphStyle(
        'TableCellBold',
        parent=base_styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=10.5,
        textColor=colors.HexColor("#0F172A")
    )

    styles['TableCellCode'] = ParagraphStyle(
        'TableCellCode',
        parent=base_styles['Normal'],
        fontName='Courier',
        fontSize=7.0,
        leading=9.5,
        textColor=colors.HexColor("#C2410C")
    )

    styles['Ques'] = ParagraphStyle(
        'Ques',
        parent=base_styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=5,
        spaceAfter=2,
        keepWithNext=True
    )

    styles['Ans'] = ParagraphStyle(
        'Ans',
        parent=base_styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11.5,
        textColor=colors.HexColor("#334155"),
        spaceAfter=5
    )

    def p(text, style_name='Body'):
        return Paragraph(text, styles[style_name])

    story = []

    # ==========================================
    # COVER PAGE
    # ==========================================
    cover_table_data = [
        [
            Paragraph("FLUTTER &amp; FIREBASE RECIPE APP", styles['CoverTitle']),
        ],
        [
            Paragraph("Comprehensive Codebase Documentation &amp; University Viva Handbook", styles['CoverSubtitle']),
        ],
        [
            Paragraph("A complete, production-grade architectural guide, full codebase inventory, Cloud Firestore schema analysis, state management breakdown, automated test audit, and a 105+ viva question defense bank tailored for Mobile Application Development Lab examinations.", styles['CoverDesc']),
        ]
    ]

    cover_table = Table(cover_table_data, colWidths=[504])
    cover_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#0F172A")),
        ('TOPPADDING', (0, 0), (-1, -1), 22),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 22),
        ('LEFTPADDING', (0, 0), (-1, -1), 20),
        ('RIGHTPADDING', (0, 0), (-1, -1), 20),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))

    story.append(Spacer(1, 10))
    story.append(cover_table)
    story.append(Spacer(1, 14))

    meta_table_data = [
        [p("<b>Student Name</b>", 'CoverMetaLabel'), p("SOURAV DEBNATH", 'CoverMetaVal')],
        [p("<b>Student ID / Roll</b>", 'CoverMetaLabel'), p("22CSE009", 'CoverMetaVal')],
        [p("<b>Institutional Email</b>", 'CoverMetaLabel'), p("sdebnath22.cse@bu.ac.bd", 'CoverMetaVal')],
        [p("<b>GitHub Repository</b>", 'CoverMetaLabel'), p("github.com/SOURAVcse9/recipe-app-flutter-firebase", 'CoverMetaVal')],
        [p("<b>Course Title</b>", 'CoverMetaLabel'), p("Mobile Application Development Lab Final Exam &amp; Viva", 'CoverMetaVal')],
        [p("<b>Technology Stack</b>", 'CoverMetaLabel'), p("Flutter 3.47+ / Dart 3.13+, Firebase Auth, Cloud Firestore, FCM, Provider 6.1.5+", 'CoverMetaVal')],
        [p("<b>Verification Status</b>", 'CoverMetaLabel'), p("54/54 Tests Passed, 0 Analyzer Errors, 0 Warnings, Production Ready", 'CoverMetaVal')],
        [p("<b>Document Version</b>", 'CoverMetaLabel'), p("Version 2.0 (Verified Against Actual Codebase)", 'CoverMetaVal')]
    ]

    meta_table = Table(meta_table_data, colWidths=[140, 364])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))

    story.append(meta_table)
    story.append(Spacer(1, 14))

    key_features_box = [
        [p("<b>Core System Highlights &amp; Architectural Strengths</b>", 'TableHead')],
        [p(
            "- <b>Clean 3-Tier Layered Architecture:</b> Presentation (UI/Screens/Widgets) -> State Management (ChangeNotifier/Provider) -> Data Access (Repositories/Firestore Streams).<br/>"
            "- <b>Role-Based Access Control (RBAC):</b> Dynamic routing based on Firebase Custom Claims (<font face='Courier'>token.admin == true</font>) for Admin vs Audience experiences.<br/>"
            "- <b>Strict Spark Plan Optimization:</b> High-performance external HTTPS image URLs with caching; Zero Firebase Storage or Cloud Function overhead.<br/>"
            "- <b>Interactive Servings Scaler:</b> Dynamic client-side arithmetic scaling for ingredients (<font face='Courier'>IngredientScaler</font>) supporting fractional servings.<br/>"
            "- <b>Atomic Firestore Transactions:</b> Real-time rolling average rating &amp; review count calculations ensuring concurrent multi-user consistency.<br/>"
            "- <b>Offline-First Local Sync:</b> Hybrid synchronization with <font face='Courier'>SharedPreferences</font> and Cloud Firestore for user preferences and theme switching.",
            'TableCell'
        )]
    ]
    kf_table = Table(key_features_box, colWidths=[504])
    kf_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#C2410C")),
        ('BACKGROUND', (0, 1), (-1, 1), colors.HexColor("#FFF7ED")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#FDBA74")),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))
    story.append(kf_table)

    story.append(PageBreak())

    # ==========================================
    # TABLE OF CONTENTS
    # ==========================================
    story.append(p("TABLE OF CONTENTS", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#C2410C"), spaceBefore=2, spaceAfter=10))

    toc_data = [
        [p("<b>Section</b>", 'TableHead'), p("<b>Topic &amp; Coverage</b>", 'TableHead'), p("<b>Key Code Focus</b>", 'TableHead')],
        [p("<b>Section 1</b>", 'TableCellBold'), p("Executive Summary &amp; System Overview", 'TableCell'), p("Project Goals, Tech Stack, Spark Plan Architecture", 'TableCellCode')],
        [p("<b>Section 2</b>", 'TableCellBold'), p("High-Level Software Architecture &amp; Patterns", 'TableCell'), p("Clean Architecture, Provider, Unidirectional Data Flow", 'TableCellCode')],
        [p("<b>Section 3</b>", 'TableCellBold'), p("Complete Codebase &amp; Directory Inventory", 'TableCell'), p("Every File in lib/ (Models, Repos, Providers, Screens)", 'TableCellCode')],
        [p("<b>Section 4</b>", 'TableCellBold'), p("Cloud Firestore Database &amp; Security Rules", 'TableCell'), p("Collections, Subcollections, firestore.rules, RBAC", 'TableCellCode')],
        [p("<b>Section 5</b>", 'TableCellBold'), p("State Management Deep Dive (Provider Pattern)", 'TableCell'), p("MultiProvider, ChangeNotifier, Consumer, Watch/Read", 'TableCellCode')],
        [p("<b>Section 6</b>", 'TableCellBold'), p("Feature-by-Feature Technical Implementation", 'TableCell'), p("Auth, Recipe CRUD, Servings Scaler, Reviews, Shopping List", 'TableCellCode')],
        [p("<b>Section 7</b>", 'TableCellBold'), p("Quality Assurance &amp; Automated Test Suite", 'TableCell'), p("54 Tests, Unit &amp; Widget Tests, Static Analysis", 'TableCellCode')],
        [p("<b>Section 8</b>", 'TableCellBold'), p("Comprehensive University Viva Bank (105 Q&amp;A)", 'TableCell'), p("Flutter, Dart, Provider, Firebase, Codebase Defense", 'TableCellCode')],
        [p("<b>Section 9</b>", 'TableCellBold'), p("Top 50 'Teacher May Ask This' High-Probability Q&amp;A", 'TableCell'), p("Exact Code File Pointers, Function Explanations", 'TableCellCode')],
        [p("<b>Section 10</b>", 'TableCellBold'), p("Presentation &amp; Live Demonstration Strategy Guide", 'TableCell'), p("Elevator Pitch, Demo Script, Handling Edge Cases", 'TableCellCode')]
    ]

    toc_table = Table(toc_data, colWidths=[65, 239, 200])
    toc_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F172A")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(toc_table)
    story.append(Spacer(1, 10))

    # ==========================================
    # SECTION 1: EXECUTIVE SUMMARY
    # ==========================================
    story.append(p("SECTION 1: EXECUTIVE SUMMARY &amp; SYSTEM OVERVIEW", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>1.1 Project Mission &amp; Purpose</b>", 'H2'))
    story.append(p(
        "The Recipe App is a cloud-synced, cross-platform mobile application developed using Flutter and Firebase. "
        "It provides a complete recipe discovery, cooking guidance, and meal planning platform with distinct experiences for two user roles: "
        "<b>Audience/General Users</b> and <b>Administrators</b>."
    ))
    story.append(p(
        "- <b>Audience Persona:</b> Allows culinary enthusiasts to explore published recipes, filter by category, dynamically scale ingredient portions based on desired servings, manage interactive shopping checklists, bookmark favorites, maintain cooking history, submit reviews with ratings, and customize display preferences.<br/>"
        "- <b>Administrator Persona:</b> Empowers content managers to perform full CRUD operations on recipes and categories, toggle publication visibility (<font face='Courier'>isPublished</font>), manage category taxonomy, and monitor engagement metrics."
    ))

    story.append(p("<b>1.2 Firebase Spark Plan Optimization (Zero Storage / Functions Constraint)</b>", 'H2'))
    story.append(p(
        "A standout architectural achievement of this project is its strict compliance with the <b>Firebase Spark Plan (Free Tier)</b>. "
        "Traditional Flutter apps rely heavily on Firebase Storage for media uploads and Cloud Functions for backend computation. "
        "In this project:<br/>"
        "1. <b>External HTTPS Image Architecture:</b> Images are stored as validated HTTPS URL strings directly within Firestore documents. The <font face='Courier'>SafeNetworkImage</font> widget delivers seamless caching, loading skeletons, and fallback graphics without incurring storage/bandwidth costs.<br/>"
        "2. <b>Client-Side Mathematical Scaling:</b> The <font face='Courier'>IngredientScaler</font> utility computes fractional and decimal ingredient portions dynamically on the client device, avoiding server compute costs.<br/>"
        "3. <b>Atomic Transactions in Repositories:</b> Average ratings and review counts are updated atomically on the client side using Firestore transactions (<font face='Courier'>runTransaction</font>) without requiring Cloud Functions."
    ))

    story.append(Spacer(1, 6))

    # ==========================================
    # SECTION 2: HIGH-LEVEL ARCHITECTURE
    # ==========================================
    story.append(p("SECTION 2: HIGH-LEVEL SOFTWARE ARCHITECTURE &amp; DESIGN PATTERNS", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>2.1 Layered Clean Architecture</b>", 'H2'))
    story.append(p(
        "The application strictly adheres to the <b>Layered Clean Architecture</b> pattern, enforcing unidirectional data flow and strong separation of concerns across 4 distinct tiers:"
    ))

    arch_layers = [
        [p("<b>Architectural Layer</b>", 'TableHead'), p("<b>Responsibility &amp; Core Classes</b>", 'TableHead'), p("<b>Interaction Rules</b>", 'TableHead')],
        [
            p("<b>Presentation Layer (UI)</b>", 'TableCellBold'),
            p("Screens (<font face='Courier'>lib/screens/</font>) and Reusable Widgets (<font face='Courier'>lib/widgets/</font>). Renders UI and captures user intent.", 'TableCell'),
            p("Listens to Providers via <font face='Courier'>Consumer</font> or <font face='Courier'>context.watch</font>. Dispatches actions via <font face='Courier'>context.read</font>. Never accesses Repositories directly.", 'TableCell')
        ],
        [
            p("<b>State Management Layer</b>", 'TableCellBold'),
            p("Providers (<font face='Courier'>lib/providers/</font>) extending <font face='Courier'>ChangeNotifier</font>. Maintains in-memory reactive state.", 'TableCell'),
            p("Subscribes to repository streams. Calls <font face='Courier'>notifyListeners()</font> on state mutations. Encapsulates business logic.", 'TableCell')
        ],
        [
            p("<b>Data Access Layer (Repository)</b>", 'TableCellBold'),
            p("Repositories (<font face='Courier'>lib/repositories/</font>). Encapsulates all Firestore queries, transactions, batch writes, and auth calls.", 'TableCell'),
            p("Converts Firestore JSON/snapshots into strongly typed Dart Models. Shields Providers from Firebase SDK specifics.", 'TableCell')
        ],
        [
            p("<b>Backend / Infrastructure Layer</b>", 'TableCellBold'),
            p("Cloud Firestore, Firebase Authentication, Firebase Cloud Messaging, SharedPreferences.", 'TableCell'),
            p("Provides persistent cloud and local storage, real-time snapshot streams, and identity verification.", 'TableCell')
        ]
    ]

    arch_table = Table(arch_layers, colWidths=[100, 214, 190])
    arch_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F172A")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(arch_table)

    # ==========================================
    # SECTION 3: CODEBASE INVENTORY
    # ==========================================
    story.append(PageBreak())
    story.append(p("SECTION 3: COMPLETE CODEBASE &amp; DIRECTORY INVENTORY", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p(
        "Below is an exhaustive, non-hallucinated directory audit of every Dart source file in the <font face='Courier'>lib/</font> folder:"
    ))

    code_inventory = [
        [p("<b>File Path</b>", 'TableHead'), p("<b>Primary Class / Function</b>", 'TableHead'), p("<b>Key Responsibilities &amp; Dependencies</b>", 'TableHead')],
        
        # Core
        [p("lib/main.dart", 'TableCellCode'), p("main(), RecipeApp, AuthWrapper", 'TableCellBold'), p("App entry point. Initializes Firebase, configures MultiProvider (6 providers), mounts MaterialApp with theme and dynamic AuthWrapper routing.", 'TableCell')],
        [p("lib/firebase_options.dart", 'TableCellCode'), p("DefaultFirebaseOptions", 'TableCellBold'), p("Auto-generated Firebase platform configuration for Android, Web, and Windows.", 'TableCell')],
        
        # Models
        [p("lib/models/recipe.dart", 'TableCellCode'), p("Recipe, IngredientItem", 'TableCellBold'), p("Primary recipe entity. Handles deserialization from Firestore, supporting both structured ingredient objects and legacy parallel lists (name/amount/image).", 'TableCell')],
        [p("lib/models/food_category.dart", 'TableCellCode'), p("FoodCategory", 'TableCellBold'), p("Category taxonomy entity (id, name, image, isActive, searchName).", 'TableCell')],
        [p("lib/models/review.dart", 'TableCellCode'), p("Review", 'TableCellBold'), p("User feedback model (id, recipeId, userId, userName, rating, reviewText, createdAt).", 'TableCell')],
        [p("lib/models/shopping_list_item.dart", 'TableCellCode'), p("ShoppingListItem", 'TableCellBold'), p("Shopping checklist item (id, name, amount, completed, recipeId, recipeName).", 'TableCell')],
        [p("lib/models/recently_viewed.dart", 'TableCellCode'), p("RecentlyViewed", 'TableCellBold'), p("User browsing history entity with timestamps and recipe metadata snapshots.", 'TableCell')],
        [p("lib/models/app_preferences.dart", 'TableCellCode'), p("AppPreferences", 'TableCellBold'), p("User settings entity (themeMode, defaultServings, showCalories, showCookTime, notification toggles).", 'TableCell')],

        # Repositories
        [p("lib/repositories/auth_repository.dart", 'TableCellCode'), p("AuthRepository", 'TableCellBold'), p("Firebase Auth wrapper: email/password sign-in, Google Sign-In, sign-up, password reset, token refresh, and custom claims verification (isAdmin).", 'TableCell')],
        [p("lib/repositories/recipe_repository.dart", 'TableCellCode'), p("RecipeRepository", 'TableCellBold'), p("Firestore CRUD for /recipes and /categories. Real-time streams: watchPublishedRecipes(), watchActiveCategories(), favorites management, and view count incrementation.", 'TableCell')],
        [p("lib/repositories/review_repository.dart", 'TableCellCode'), p("ReviewRepository", 'TableCellBold'), p("Manages /recipes/{id}/reviews. Implements atomic runTransaction to calculate rolling average ratings and update aggregate review counts.", 'TableCell')],
        [p("lib/repositories/shopping_list_repository.dart", 'TableCellCode'), p("ShoppingListRepository", 'TableCellBold'), p("Manages /users/{uid}/shoppingList. Uses batch writes (WriteBatch) for atomic multi-ingredient insertions and clears.", 'TableCell')],
        [p("lib/repositories/recently_viewed_repository.dart", 'TableCellCode'), p("RecentlyViewedRepository", 'TableCellBold'), p("Manages /users/{uid}/recentlyViewed with server timestamps for chronological history.", 'TableCell')],
        [p("lib/repositories/preferences_repository.dart", 'TableCellCode'), p("PreferencesRepository", 'TableCellBold'), p("Dual-sync persistence: stores settings in SharedPreferences for instant boot and syncs to /users/{uid}/preferences/settings in Firestore.", 'TableCell')],

        # Providers
        [p("lib/providers/auth_provider.dart", 'TableCellCode'), p("AuthProvider", 'TableCellBold'), p("Manages user session, login, signup, Google auth, role verification (isAdmin flag), and error messaging.", 'TableCell')],
        [p("lib/providers/recipe_provider.dart", 'TableCellCode'), p("RecipeProvider", 'TableCellBold'), p("Central state for recipes, categories, selectedCategory, searchQuery, favoriteIds set, and admin CRUD dispatching.", 'TableCell')],
        [p("lib/providers/review_provider.dart", 'TableCellCode'), p("ReviewProvider", 'TableCellBold'), p("Controls review streaming, rating submission states, and user review queries.", 'TableCell')],
        [p("lib/providers/shopping_list_provider.dart", 'TableCellCode'), p("ShoppingListProvider", 'TableCellBold'), p("Maintains active shopping list stream, checkbox toggles, batch additions from recipe details, and completion filters.", 'TableCell')],
        [p("lib/providers/recently_viewed_provider.dart", 'TableCellCode'), p("RecentlyViewedProvider", 'TableCellBold'), p("Streams recently viewed recipe list and records recipe inspection events.", 'TableCell')],
        [p("lib/providers/preferences_provider.dart", 'TableCellCode'), p("PreferencesProvider", 'TableCellBold'), p("Controls dynamic ThemeMode (Light/Dark/System) and user configuration states.", 'TableCell')],

        # Services & Utils
        [p("lib/services/notification_service.dart", 'TableCellCode'), p("NotificationService", 'TableCellBold'), p("FCM push notification initialization, foreground handlers, and device token sync to Firestore.", 'TableCell')],
        [p("lib/utils/app_theme.dart", 'TableCellCode'), p("AppTheme", 'TableCellBold'), p("Defines Light and Dark ThemeData with primary coral accent (#FF5A36), custom card shapes, and typography.", 'TableCell')],
        [p("lib/utils/ingredient_scaler.dart", 'TableCellCode'), p("IngredientScaler", 'TableCellBold'), p("Dynamic serving multiplier utility. Parses fractions/decimals and scales quantities cleanly without decimals.", 'TableCell')],
        [p("lib/utils/image_url_validator.dart", 'TableCellCode'), p("ImageUrlValidator", 'TableCellBold'), p("Strict HTTPS validation utility to prevent broken URLs or non-secure image loads.", 'TableCell')],

        # Widgets
        [p("lib/widgets/safe_network_image.dart", 'TableCellCode'), p("SafeNetworkImage", 'TableCellBold'), p("Production-grade image widget with shimmer skeleton loading and graceful error fallback icons.", 'TableCell')],
        [p("lib/widgets/recipe_card.dart", 'TableCellCode'), p("RecipeCard", 'TableCellBold'), p("Card UI displaying recipe image, rating badge, cook time, calories, and favorite toggle button.", 'TableCell')],
        [p("lib/widgets/category_chip.dart", 'TableCellCode'), p("CategoryChip", 'TableCellBold'), p("Horizontal filter chip for food categories with active state styling.", 'TableCell')],
        [p("lib/widgets/quantity_selector.dart", 'TableCellCode'), p("QuantitySelector", 'TableCellBold'), p("Interactive counter (+ / -) for dynamic recipe serving scaling.", 'TableCell')],
        [p("lib/widgets/timer_widget.dart", 'TableCellCode'), p("CookingTimerWidget", 'TableCellBold'), p("Interactive cooking timer with start/pause/reset controls and progress indicator.", 'TableCell')],
        [p("lib/widgets/rating_widget.dart", 'TableCellCode'), p("StarRatingWidget", 'TableCellBold'), p("Interactive 5-star rating selector and display widget.", 'TableCell')],
        [p("lib/widgets/state_views.dart", 'TableCellCode'), p("LoadingView, EmptyStateView, ErrorView", 'TableCellBold'), p("Standardized UI states for loading spinners, empty search results, and network retry views.", 'TableCell')],

        # Screens - Audience & Auth
        [p("lib/screens/main_navigation.dart", 'TableCellCode'), p("MainNavigation", 'TableCellBold'), p("Audience bottom navigation bar scaffolding (Home, Favorites, Shopping List, Profile).", 'TableCell')],
        [p("lib/screens/home_screen.dart", 'TableCellCode'), p("HomeScreen", 'TableCellBold'), p("Audience home dashboard: search bar, category carousel, popular/top-rated sections, and recipe grid.", 'TableCell')],
        [p("lib/screens/recipe_detail_screen.dart", 'TableCellCode'), p("RecipeDetailScreen", 'TableCellBold'), p("Detailed recipe view: dynamic serving scaler, ingredient checklist, add-to-shopping-list, cooking steps, timer, and reviews.", 'TableCell')],
        [p("lib/screens/shopping_list_screen.dart", 'TableCellCode'), p("ShoppingListScreen", 'TableCellBold'), p("Interactive shopping list with checkmark completion, swipe-to-delete, and batch clear.", 'TableCell')],
        [p("lib/screens/favorites_screen.dart", 'TableCellCode'), p("FavoritesScreen", 'TableCellBold'), p("Bookmarked recipes screen filtering recipes by favorite IDs.", 'TableCell')],
        [p("lib/screens/profile_screen.dart", 'TableCellCode'), p("ProfileScreen", 'TableCellBold'), p("User profile view with navigation to preferences, recently viewed, reviews, and sign-out.", 'TableCell')],
        [p("lib/screens/login_screen.dart", 'TableCellCode'), p("LoginScreen", 'TableCellBold'), p("Email/password and Google Sign-In interface with input validation and loading spinners.", 'TableCell')],
        [p("lib/screens/signup_screen.dart", 'TableCellCode'), p("SignupScreen", 'TableCellBold'), p("User registration form with name, email, password, and instant sign-in.", 'TableCell')],
        
        # Screens - Admin
        [p("lib/screens/admin/admin_dashboard_screen.dart", 'TableCellCode'), p("AdminDashboardScreen", 'TableCellBold'), p("Admin portal entry point: summary stat cards, quick navigation to Recipe and Category management.", 'TableCell')],
        [p("lib/screens/admin/admin_recipes_screen.dart", 'TableCellCode'), p("AdminRecipesScreen", 'TableCellBold'), p("Admin recipe list view with publish status toggle, edit navigation, and delete confirmation dialogs.", 'TableCell')],
        [p("lib/screens/admin/add_recipe_screen.dart", 'TableCellCode'), p("AddRecipeScreen", 'TableCellBold'), p("Admin form to create new recipes: HTTPS image input, dynamic ingredient adder, instruction steps, and category picker.", 'TableCell')],
        [p("lib/screens/admin/edit_recipe_screen.dart", 'TableCellCode'), p("EditRecipeScreen", 'TableCellBold'), p("Admin form to update existing recipes with pre-populated form fields and validation.", 'TableCell')],
        [p("lib/screens/admin/admin_categories_screen.dart", 'TableCellCode'), p("AdminCategoriesScreen", 'TableCellBold'), p("Admin category management list with active toggle and edit/delete actions.", 'TableCell')],
        [p("lib/screens/admin/add_category_screen.dart", 'TableCellCode'), p("AddCategoryScreen", 'TableCellBold'), p("Admin form to add categories with name, HTTPS image URL, and active status.", 'TableCell')],
        [p("lib/screens/admin/edit_category_screen.dart", 'TableCellCode'), p("EditCategoryScreen", 'TableCellBold'), p("Admin form to update category name, image URL, and active visibility.", 'TableCell')]
    ]

    inv_table = Table(code_inventory, colWidths=[120, 114, 270])
    inv_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F172A")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(inv_table)

    # ==========================================
    # SECTION 4: FIRESTORE & SECURITY RULES
    # ==========================================
    story.append(PageBreak())
    story.append(p("SECTION 4: CLOUD FIRESTORE DATABASE ARCHITECTURE &amp; SECURITY RULES", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>4.1 Cloud Firestore Collections Schema</b>", 'H2'))
    story.append(p(
        "The application utilizes a NoSQL document-oriented structure organized into top-level shared collections and user-isolated subcollections:"
    ))

    schema_data = [
        [p("<b>Collection / Path</b>", 'TableHead'), p("<b>Document Fields &amp; Data Types</b>", 'TableHead'), p("<b>Purpose &amp; Access Scope</b>", 'TableHead')],
        [
            p("/recipes/{recipeId}", 'TableCellCode'),
            p("<b>title:</b> String<br/><b>description:</b> String<br/><b>image:</b> String (HTTPS URL)<br/><b>category:</b> String<br/><b>calories:</b> int<br/><b>time:</b> String (e.g. '25 Mins')<br/><b>rate:</b> double<br/><b>rating:</b> double<br/><b>review:</b> int (count)<br/><b>servings:</b> int<br/><b>isPublished:</b> bool<br/><b>viewCount:</b> int<br/><b>ingredients:</b> List&lt;Map&gt;<br/><b>instructions:</b> List&lt;String&gt;<br/><b>createdAt, updatedAt:</b> Timestamp", 'TableCell'),
            p("<b>Shared Public Collection:</b> Stores all recipe records. Read access is public. Write/Delete access is restricted exclusively to Admins (<font face='Courier'>token.admin == true</font>). Authenticated users can update only aggregate stats.", 'TableCell')
        ],
        [
            p("/recipes/{id}/reviews/{revId}", 'TableCellCode'),
            p("<b>userId:</b> String<br/><b>userName:</b> String<br/><b>rating:</b> double<br/><b>reviewText:</b> String<br/><b>createdAt:</b> Timestamp<br/><b>updatedAt:</b> Timestamp", 'TableCell'),
            p("<b>Recipe Reviews Subcollection:</b> Stores user comments and ratings for a specific recipe. Public read; Created/Edited/Deleted only by the author or Admin.", 'TableCell')
        ],
        [
            p("/categories/{categoryId}", 'TableCellCode'),
            p("<b>name:</b> String<br/><b>image:</b> String (HTTPS URL)<br/><b>isActive:</b> bool<br/><b>searchName:</b> String (lowercase)", 'TableCell'),
            p("<b>Shared Taxonomy:</b> Food categories. Public read; Admin-only write.", 'TableCell')
        ],
        [
            p("/users/{uid}/favorites/{recipeId}", 'TableCellCode'),
            p("<b>recipeId:</b> String<br/><b>savedAt:</b> Timestamp", 'TableCell'),
            p("<b>User Subcollection:</b> Bookmarked recipe IDs. Strictly isolated to the owner (<font face='Courier'>request.auth.uid == uid</font>).", 'TableCell')
        ],
        [
            p("/users/{uid}/shoppingList/{itemId}", 'TableCellCode'),
            p("<b>name:</b> String<br/><b>amount:</b> String<br/><b>completed:</b> bool<br/><b>recipeId:</b> String<br/><b>recipeName:</b> String<br/><b>createdAt:</b> Timestamp", 'TableCell'),
            p("<b>User Subcollection:</b> Shopping checklist items. Supports atomic batch inserts and toggle updates. Isolated to owner.", 'TableCell')
        ],
        [
            p("/users/{uid}/recentlyViewed/{recipeId}", 'TableCellCode'),
            p("<b>recipeId:</b> String<br/><b>recipeName:</b> String<br/><b>recipeImage:</b> String<br/><b>category:</b> String<br/><b>calories:</b> int<br/><b>cookTime:</b> String<br/><b>rating:</b> double<br/><b>viewedAt:</b> Timestamp", 'TableCell'),
            p("<b>User Subcollection:</b> Chronological browsing history snapshots. Strict UID isolation.", 'TableCell')
        ],
        [
            p("/users/{uid}/preferences/settings", 'TableCellCode'),
            p("<b>themeMode:</b> String ('light'/'dark'/'system')<br/><b>defaultServings:</b> int<br/><b>showCalories:</b> bool<br/><b>showCookTime:</b> bool<br/><b>notificationsEnabled:</b> bool", 'TableCell'),
            p("<b>User Document:</b> Cloud sync of user preferences. Strict UID isolation.", 'TableCell')
        ],
        [
            p("/users/{uid}/notification_tokens/{token}", 'TableCellCode'),
            p("<b>fcmToken:</b> String<br/><b>device:</b> String<br/><b>updatedAt:</b> Timestamp", 'TableCell'),
            p("<b>User Subcollection:</b> Push notification device tokens for FCM targeted messaging.", 'TableCell')
        ]
    ]

    schema_table = Table(schema_data, colWidths=[120, 204, 180])
    schema_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F172A")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.append(schema_table)
    story.append(Spacer(1, 8))

    story.append(p("<b>4.2 Security Rules Architecture (<font face='Courier'>firestore.rules</font>)</b>", 'H2'))
    story.append(p(
        "The project enforces a strict, production-grade security policy directly in Cloud Firestore rules:"
    ))
    story.append(p(
        "1. <b>Role-Based Admin Protection:</b> Helper function <font face='Courier'>isAdmin()</font> inspects the cryptographically signed JWT token: "
        "<font face='Courier'>request.auth != null &amp;&amp; request.auth.token.admin == true</font>. Only tokens with the admin custom claim can create, update, or delete recipes and categories.<br/>"
        "2. <b>Field-Level Update Whitelist:</b> Authenticated users can modify existing recipes <i>only</i> if the diff touches exclusively rating and view metrics: "
        "<font face='Courier'>request.resource.data.diff(resource.data).affectedKeys().hasOnly(['rating', 'review', 'viewCount'])</font>.<br/>"
        "3. <b>Strict User Isolation:</b> All subcollections under <font face='Courier'>/users/{uid}/**</font> require <font face='Courier'>request.auth.uid == uid</font>, preventing any user from reading or modifying another user's private data.<br/>"
        "4. <b>Default Deny:</b> The catch-all rule <font face='Courier'>match /{document=**} { allow read, write: if false; }</font> guarantees zero security loopholes."
    ))

    # ==========================================
    # SECTION 5: STATE MANAGEMENT
    # ==========================================
    story.append(PageBreak())
    story.append(p("SECTION 5: STATE MANAGEMENT DEEP DIVE (PROVIDER PATTERN)", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>5.1 MultiProvider Registration in <font face='Courier'>lib/main.dart</font></b>", 'H2'))
    story.append(p(
        "State management is orchestrated via the <font face='Courier'>provider</font> package (v6.1.5+). "
        "All application providers are registered at the root of the widget tree using <font face='Courier'>MultiProvider</font> to ensure unified dependency injection:"
    ))

    provider_code = """MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => RecipeProvider()),
    ChangeNotifierProvider(create: (_) => PreferencesProvider()),
    ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
    ChangeNotifierProvider(create: (_) => RecentlyViewedProvider()),
    ChangeNotifierProvider(create: (_) => ReviewProvider()),
  ],
  child: const RecipeApp(),
);"""
    story.append(p(provider_code, 'CodeBlock'))

    story.append(p("<b>5.2 Provider Consumption Strategies: Watch vs Read vs Consumer</b>", 'H2'))
    story.append(p(
        "The codebase strictly observes optimal Flutter performance guidelines regarding widget rebuilds:"
    ))
    story.append(p(
        "- <b><font face='Courier'>context.watch&lt;T&gt;()</font>:</b> Subscribes the widget to changes in Provider <font face='Courier'>T</font>. Used in top-level view builders where the whole screen depends on state (e.g. <font face='Courier'>HomeScreen</font> watching recipe lists).<br/>"
        "- <b><font face='Courier'>context.read&lt;T&gt;()</font>:</b> Retrieves the provider instance without listening for updates. Exclusively used inside event handlers and button callbacks (e.g., <font face='Courier'>onPressed: () =&gt; context.read&lt;AuthProvider&gt;().signOut()</font>) to prevent unnecessary widget rebuilds.<br/>"
        "- <b><font face='Courier'>Consumer&lt;T&gt;</font>:</b> Scopes widget rebuilds to granular sub-trees (e.g. wrapping only the <font face='Courier'>FavoriteButton</font> rather than the entire <font face='Courier'>RecipeCard</font>)."
    ))

    story.append(p("<b>5.3 Unidirectional Reactive Stream Flow</b>", 'H2'))
    story.append(p(
        "1. Firestore documents change in the cloud -> 2. Real-time stream emits snapshot in <font face='Courier'>RecipeRepository</font> -> "
        "3. <font face='Courier'>RecipeProvider</font> receives typed model list -> 4. Provider executes <font face='Courier'>notifyListeners()</font> -> "
        "5. Flutter UI widgets selectively rebuild with 60 FPS fluidity."
    ))

    # ==========================================
    # SECTION 6: FEATURE BREAKDOWN
    # ==========================================
    story.append(Spacer(1, 8))
    story.append(p("SECTION 6: FEATURE-BY-FEATURE TECHNICAL IMPLEMENTATION", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>6.1 Dynamic Ingredient Serving Scaler (<font face='Courier'>IngredientScaler</font>)</b>", 'H2'))
    story.append(p(
        "In <font face='Courier'>lib/utils/ingredient_scaler.dart</font>, the <font face='Courier'>scaleAmount(String rawAmount, int baseServings, int targetServings)</font> function performs intelligent portion arithmetic:<br/>"
        "- Multiplier formula: <font face='Courier'>factor = targetServings / baseServings</font>.<br/>"
        "- Parses whole numbers, fractions (e.g., '1/2 cup' -> '1 cup' when doubled), and mixed fractions ('1 1/2 tbsp' -> '3 tbsp').<br/>"
        "- Formats clean integers without trailing decimals (e.g., outputs '2' instead of '2.0')."
    ))

    story.append(p("<b>6.2 Atomic Review &amp; Rating Calculations</b>", 'H2'))
    story.append(p(
        "In <font face='Courier'>lib/repositories/review_repository.dart</font>, submitting a review executes a Firestore transaction:<br/>"
        "- If the user has an existing review, the old rating is subtracted and the new rating added without incrementing the review count.<br/>"
        "- Formula for new review: <font face='Courier'>newAvg = ((currentRating * currentCount) + newRating) / (currentCount + 1)</font>.<br/>"
        "- Writes review to subcollection and updates aggregate fields on recipe document simultaneously."
    ))

    story.append(p("<b>6.3 Shopping List Batch Operations</b>", 'H2'))
    story.append(p(
        "In <font face='Courier'>lib/repositories/shopping_list_repository.dart</font>, adding all recipe ingredients uses <font face='Courier'>FirebaseFirestore.instance.batch()</font>. "
        "All ingredients are committed in a single atomic network request, drastically reducing latency and write operations."
    ))

    # ==========================================
    # SECTION 7: QUALITY ASSURANCE & TESTING
    # ==========================================
    story.append(PageBreak())
    story.append(p("SECTION 7: QUALITY ASSURANCE, AUTOMATED TESTING &amp; VERIFICATION", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>7.1 Automated Test Suite Summary (54/54 Tests Passing)</b>", 'H2'))
    story.append(p(
        "The project includes a comprehensive automated test suite covering unit logic, state management, data integrity, and widget rendering:"
    ))

    test_data = [
        [p("<b>Test File Path</b>", 'TableHead'), p("<b>Test Category &amp; Coverage</b>", 'TableHead'), p("<b>Assertions &amp; Invariants Tested</b>", 'TableHead')],
        [p("test/ingredient_scaler_test.dart", 'TableCellCode'), p("Unit Test: Portion Scaler", 'TableCellBold'), p("Verifies fraction parsing (1/2, 1/4), mixed fractions, whole number scaling, unit preservation, and zero edge cases.", 'TableCell')],
        [p("test/image_url_validator_test.dart", 'TableCellCode'), p("Unit Test: URL Sanitizer", 'TableCellBold'), p("Enforces strict HTTPS scheme, rejects HTTP/FTP/file URLs, validates image extensions (.jpg, .png, .webp, unsplash).", 'TableCell')],
        [p("test/recipe_data_validation_test.dart", 'TableCellCode'), p("Unit Test: Model Serialization", 'TableCellBold'), p("Tests Recipe.fromFirestore() with parallel lists, missing fields, backward compatibility, and null safety defaults.", 'TableCell')],
        [p("test/recipe_provider_test.dart", 'TableCellCode'), p("State Test: RecipeProvider", 'TableCellBold'), p("Tests category filtering, search query normalization, favorite toggling, and state mutation notifications.", 'TableCell')],
        [p("test/phase2_test.dart", 'TableCellCode'), p("Integration Test: User Flows", 'TableCellBold'), p("Tests shopping list item completion, preferences persistence, and recently viewed timestamping.", 'TableCell')],
        [p("test/phase3_test.dart", 'TableCellCode'), p("Integration Test: Reviews &amp; Ratings", 'TableCellBold'), p("Tests rolling average math, review updates, transaction rollback handling, and subcollection indexing.", 'TableCell')],
        [p("test/phase4_admin_test.dart", 'TableCellCode'), p("Security &amp; Admin Test", 'TableCellBold'), p("Validates admin role enforcement, isPublished flag toggles, category creation, and non-admin write rejection.", 'TableCell')],
        [p("test/profile_navigation_test.dart", 'TableCellCode'), p("Widget Test: UI Navigation", 'TableCellBold'), p("Verifies profile screen routes to Preferences, Shopping List, Reviews, and About screens.", 'TableCell')],
        [p("test/widget_test.dart", 'TableCellCode'), p("Widget Test: Component Smoke", 'TableCellBold'), p("Tests SafeNetworkImage fallback icons, CategoryChip tap handlers, and RecipeCard rendering.", 'TableCell')]
    ]

    test_table = Table(test_data, colWidths=[130, 120, 254])
    test_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F172A")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.append(test_table)
    story.append(Spacer(1, 8))

    story.append(p("<b>7.2 Static Analysis &amp; Zero Warning Standard</b>", 'H2'))
    story.append(p(
        "Executing <font face='Courier'>flutter analyze</font> returns <b>0 issues found</b>. "
        "The codebase complies with all rules in <font face='Courier'>package:flutter_lints/flutter.yaml</font>, including strict const constructors, mandatory null safety, and clean async/await patterns."
    ))

    # ==========================================
    # SECTION 8: 105 VIVA QUESTION BANK
    # ==========================================
    story.append(PageBreak())
    story.append(p("SECTION 8: COMPREHENSIVE UNIVERSITY VIVA QUESTION BANK (105 Q&amp;A)", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>PART A: FLUTTER &amp; DART CORE FUNDAMENTALS (Q01 - Q30)</b>", 'H2'))

    viva_part_a = [
        ("Q01: What is Flutter and how does its rendering architecture work?",
         "Flutter is an open-source UI software development kit by Google. Unlike React Native or native Android that use platform OEM widgets, Flutter controls every pixel on the screen by rendering its own widget tree directly onto a Canvas using the Impeller (or Skia) graphics engine at 60/120 FPS."),
        
        ("Q02: Explain the difference between StatelessWidget and StatefulWidget.",
         "StatelessWidget is immutable; its configuration cannot change over time once built. StatefulWidget is mutable and maintains a separate State object that persists across widget rebuilds and triggers UI updates when setState() is invoked."),
        
        ("Q03: What is the Widget Tree, Element Tree, and Render Tree in Flutter?",
         "1. Widget Tree: Lightweight, immutable declarative configurations created frequently. 2. Element Tree: Manages lifecycle, acts as the bridge/glue between Widget and RenderObject. 3. Render Tree: Heavyweight mutable objects responsible for layout, sizing, and painting on screen."),
        
        ("Q04: Why are constructors in Flutter marked with 'const'?",
         "The 'const' keyword creates compile-time constants. It allows Flutter's framework to short-circuit rebuilds: if a widget has a const constructor and its parameters haven't changed, Flutter reuses the existing Element and RenderObject without reallocating memory or repainting."),
        
        ("Q05: What is the significance of the 'BuildContext' parameter in build methods?",
         "BuildContext is a handle to the location of a widget within the Element Tree. It allows widgets to look up inherited data from ancestor widgets (such as Theme.of(context), Navigator.of(context), or Provider.of<T>(context))."),
        
        ("Q06: Explain Dart's Null Safety and why it is sound.",
         "Dart features sound null safety: types are non-nullable by default (e.g. 'String' cannot be null). Nullable types must be explicitly declared with '?' (e.g. 'String?'). The compiler guarantees that a non-nullable variable can never be null at runtime, eliminating NullPointerExceptions."),
        
        ("Q07: What is the difference between 'final' and 'const' in Dart?",
         "'final' variables are immutable once initialized and their value can be set at runtime (e.g. final now = DateTime.now()). 'const' variables are compile-time constants and must be known before program execution."),
        
        ("Q08: How does Dart's asynchronous event loop work (Microtasks vs Event Queue)?",
         "Dart runs on a single-threaded isolate. The event loop continuously processes two queues: 1. Microtask Queue (higher priority, for internal microtasks like Future.microtask). 2. Event Queue (lower priority, for external events like I/O, timers, user taps, and network responses)."),
        
        ("Q09: What is a Future in Dart and how does async/await work?",
         "A Future represents a computation that doesn't complete immediately and will eventually return a value of type T or an error. 'async' marks a function as asynchronous, and 'await' pauses execution within that function until the Future completes, without blocking the UI thread."),
        
        ("Q10: What is a Stream in Dart and how does it differ from a Future?",
         "A Future delivers a single asynchronous value once. A Stream delivers a sequence of asynchronous events over time (like a pipe). In our Recipe App, Firestore data is consumed via Streams to provide real-time updates as documents change in the cloud."),

        ("Q11: What is the purpose of the 'pubspec.yaml' file?",
         "pubspec.yaml is the project configuration file. It specifies project metadata, SDK environment constraints, third-party dependencies (e.g. firebase_core, provider), dev dependencies, and assets like images and fonts."),

        ("Q12: What is the role of 'WidgetsFlutterBinding.ensureInitialized()' in main()?",
         "It initializes the binding between the Flutter engine and the native platform host before any plugins or asynchronous platform channels (like Firebase.initializeApp()) are called."),

        ("Q13: How does the 'Navigator' work in Flutter?",
         "Navigator manages a stack of Route objects. Navigator.push() pushes a new screen onto the stack, and Navigator.pop() removes the top screen to return to the previous screen."),

        ("Q14: What is the purpose of 'MaterialApp'?",
         "MaterialApp is a convenience widget that wraps the application with Material Design styling, global Theme management, Navigator routing, localization, and media query accessibility configurations."),

        ("Q15: What is a Scaffold widget?",
         "Scaffold provides the standard visual layout structure for Material Design screens, including AppBar, Body, FloatingActionButton, BottomNavigationBar, Drawer, and SnackBar display areas."),

        ("Q16: Explain the difference between 'MainAxisAlignment' and 'CrossAxisAlignment'.",
         "In a Row: MainAxis is horizontal, CrossAxis is vertical. In a Column: MainAxis is vertical, CrossAxis is horizontal. They govern how child widgets are aligned along their primary and perpendicular axes."),

        ("Q17: What is an 'Expanded' vs 'Flexible' widget?",
         "Both must be children of Flex (Row/Column). 'Expanded' forces a child to fill the remaining available space along the main axis. 'Flexible' allows a child to occupy space up to the available limit without forcing it to stretch."),

        ("Q18: How do you prevent keyboard overflow errors in forms?",
         "By wrapping the form content inside a 'SingleChildScrollView' or 'ListView', ensuring that the UI can scroll when the soft keyboard reduces the available viewport height."),

        ("Q19: What is the purpose of 'GlobalKey'?",
         "A GlobalKey provides a unique identifier for a widget across the entire app. It allows accessing the State of a widget (such as 'GlobalKey<FormState>()' to call formKey.currentState!.validate())."),

        ("Q20: What is the difference between 'ListView.builder' and 'ListView'?",
         "Standard 'ListView' constructs all children at once in memory. 'ListView.builder' creates children lazily on-demand as they scroll into the viewport, dramatically saving memory and boosting performance for long lists."),

        ("Q21: How do you handle images in Flutter without memory leaks?",
         "By using cached image widgets, specifying cache dimensions (cacheWidth/cacheHeight), and providing errorBuilder and loadingBuilder callbacks to handle failed loads gracefully."),

        ("Q22: What is an 'InheritedWidget'?",
         "An InheritedWidget is a base class that allows efficient propagation of data down the widget tree. When its data changes, all descendant widgets that registered a dependency are automatically rebuilt. Provider is built on top of InheritedWidget."),

        ("Q23: What is the difference between 'hot reload' and 'hot restart'?",
         "Hot reload injects updated source code files directly into the running Dart VM and triggers a rebuild of the widget tree while preserving the application state. Hot restart reinitializes the entire app from main() and resets the state."),

        ("Q24: What are 'keys' in Flutter and when are they required?",
         "Keys preserve the state of StatefulWidget elements when they are dynamically moved, inserted, or removed within a collection (e.g. in a reorderable list or AnimatedList)."),

        ("Q25: What is the purpose of the 'mounted' property in a State object?",
         "It returns a boolean indicating whether the State object is currently in the element tree. Checking 'if (mounted)' before calling setState() prevents exceptions when asynchronous operations finish after a widget has been disposed."),

        ("Q26: What is a 'FutureBuilder' widget?",
         "FutureBuilder is a widget that builds itself based on the latest snapshot of interaction with a Future (handling ConnectionState.waiting, hasData, and hasError states)."),

        ("Q27: What is a 'StreamBuilder' widget?",
         "StreamBuilder subscribes to a Stream and automatically rebuilds its child whenever the stream emits a new event or error, managing subscription lifecycles automatically."),

        ("Q28: How does Flutter support dark and light themes?",
         "Through MaterialApp's 'theme', 'darkTheme', and 'themeMode' properties. Setting themeMode to ThemeMode.system, ThemeMode.light, or ThemeMode.dark dynamically applies the corresponding ThemeData."),

        ("Q29: What is the difference between 'mixin' and 'class' in Dart?",
         "A mixin is a way of reusing a class's code in multiple class hierarchies without multiple inheritance. It is applied using the 'with' keyword (e.g. 'class MyState extends State<MyWidget> with SingleTickerProviderStateMixin')."),

        ("Q30: What is Dart Isolates?",
         "Dart Isolates are independent execution threads with their own private memory heaps. They do not share memory; instead, they communicate by passing messages through SendPort and ReceivePort.")
    ]

    for q, a in viva_part_a:
        story.append(p(f"<b>{q}</b>", 'Ques'))
        story.append(p(a, 'Ans'))

    story.append(PageBreak())
    story.append(p("<b>PART B: STATE MANAGEMENT &amp; PROVIDER IN THIS APP (Q31 - Q55)</b>", 'H2'))

    viva_part_b = [
        ("Q31: What is State Management and why do we need it?",
         "State is any data that changes over time and affects how the UI is rendered. State management provides a systematic architecture to share data across multiple decoupled screens, avoid prop drilling, and trigger surgical UI rebuilds."),
        
        ("Q32: Why did we choose the Provider package for this project?",
         "Provider is the officially recommended, lightweight, and intuitive state management library by Google. It wraps InheritedWidgets with developer-friendly patterns, clean lifecycle management, and excellent separation of business logic from UI."),
        
        ("Q33: What is 'ChangeNotifier' and how is it used in our app?",
         "ChangeNotifier is a class in the Flutter foundation SDK that provides change notification API. Our providers (e.g. RecipeProvider, AuthProvider) extend ChangeNotifier and call notifyListeners() whenever their internal data changes."),
        
        ("Q34: What happens under the hood when 'notifyListeners()' is called?",
         "It iterates through all registered listener callbacks (such as Consumers or context.watch widgets) and schedules them for rebuilding during the next frame."),
        
        ("Q35: What is 'MultiProvider' and where is it declared in our project?",
         "MultiProvider is a container widget that merges multiple Provider instances into a single widget tree level. In our app, it is declared in 'lib/main.dart' wrapping 'RecipeApp' with all 6 application providers."),
        
        ("Q36: Explain the 6 providers implemented in this project.",
         "1. AuthProvider: Auth session & role claims. 2. RecipeProvider: Recipes, categories, search, favorites. 3. PreferencesProvider: Theme and display toggles. 4. ShoppingListProvider: Grocery checklist items. 5. RecentlyViewedProvider: User view history. 6. ReviewProvider: Ratings & user reviews."),
        
        ("Q37: What is the difference between 'context.watch<T>()' and 'context.read<T>()'?",
         "'context.watch<T>()' makes the calling widget listen to changes in T and rebuilds whenever notifyListeners() is called. 'context.read<T>()' retrieves T without subscribing, ideal for one-off method executions like button clicks."),
        
        ("Q38: Why should you NEVER call 'context.read<T>()' inside a build() method?",
         "Calling context.read inside build() does not establish a dependency subscription. If the state changes, the widget will not rebuild, causing stale UI and hard-to-debug bugs."),
        
        ("Q39: Why should you NEVER call 'context.watch<T>()' inside a button callback?",
         "Button callbacks execute outside the build phase. Attempting to subscribe to state changes inside an event handler is a runtime violation and throws a Flutter framework exception."),
        
        ("Q40: How does 'Consumer<T>' optimize rendering performance?",
         "Consumer<T> restricts widget rebuilds to only its immediate child builder lambda. For example, in a complex RecipeCard, wrapping only the favorite heart icon in Consumer<RecipeProvider> prevents the entire card from repainting when bookmarked."),
        
        ("Q41: How does 'RecipeProvider' handle real-time Firestore stream subscriptions?",
         "RecipeProvider initializes a StreamSubscription listening to 'recipeRepository.watchPublishedRecipes()'. When a new list arrives, it updates its internal '_recipes' list and calls notifyListeners(). It also disposes the subscription in dispose()."),
        
        ("Q42: How does 'AuthProvider' detect when a user logs in or out?",
         "It listens to FirebaseAuth.instance.authStateChanges(). When a User object is emitted, it fetches token claims to determine 'isAdmin', updates the currentUser state, and notifies listeners to trigger routing in AuthWrapper."),
        
        ("Q43: What is the role of 'AuthWrapper' in lib/main.dart?",
         "AuthWrapper is a reactive gatekeeper widget. It watches AuthProvider: if user is unauthenticated, it renders LoginScreen; if authenticated as Admin, it renders AdminDashboardScreen; if authenticated as Audience, it renders MainNavigation."),
        
        ("Q44: How is Category filtering handled inside RecipeProvider?",
         "RecipeProvider holds a 'selectedCategory' string. When a user taps a category chip, 'setSelectedCategory(name)' is invoked, which updates the state and filters the recipes displayed on HomeScreen."),
        
        ("Q45: How is Search implemented in RecipeProvider?",
         "RecipeProvider holds a 'searchQuery' string. Its getter 'filteredRecipes' filters published recipes where the title or category contains the query (case-insensitive) and matches the active category filter."),
        
        ("Q46: How are Bookmarks / Favorites managed in RecipeProvider?",
         "Favorites are stored as a Set<String> of recipe IDs for O(1) constant-time lookups. When a user taps favorite, 'toggleFavorite(recipeId)' updates Firestore via RecipeRepository and updates the local Set instantly for optimistic UI response."),
        
        ("Q47: How does ShoppingListProvider manage multi-item additions?",
         "When a user taps 'Add Ingredients to Shopping List' on RecipeDetailScreen, ShoppingListProvider calls 'addItems(userId, items)' which dispatches a Firestore WriteBatch through ShoppingListRepository."),
        
        ("Q48: How does PreferencesProvider synchronize with SharedPreferences?",
         "On app startup, PreferencesProvider loads saved settings from SharedPreferences for zero-latency UI display, and asynchronously syncs with Firestore if the user is authenticated."),
        
        ("Q49: How is memory leak prevented in Providers?",
         "By overriding the 'dispose()' method to cancel active StreamSubscriptions, close stream controllers, and clean up listeners before the provider is removed from memory."),
        
        ("Q50: Can multiple providers communicate with each other?",
         "Yes, either using 'ProxyProvider' or by injecting references/dispatching actions through method calls from UI coordinators."),
        
        ("Q51: What is 'ChangeNotifierProvider.value' and when should it be used?",
         "It provides an existing instance of ChangeNotifier to another sub-tree without recreating it. It is commonly used in ListView items where each row binds to a pre-existing model."),
        
        ("Q52: What is the difference between setState() and Provider?",
         "setState() is ephemeral state management confined strictly to a single StatefulWidget. Provider is app-level/global state management accessible across decoupled screens and lifecycle boundaries."),
        
        ("Q53: How does RecentlyViewedProvider prevent duplicate history entries?",
         "By using the recipeId as the document ID in Firestore: setting the document updates the 'viewedAt' timestamp rather than creating duplicate records."),
        
        ("Q54: How does ReviewProvider update UI when a new review is submitted?",
         "ReviewProvider calls ReviewRepository.submitReview(). Upon successful transaction completion, it refreshes the active review stream and triggers SnackBar feedback."),
        
        ("Q55: What is the benefit of keeping Repositories independent of Providers?",
         "It promotes Test-Driven Development (TDD). Repositories can be easily mocked in unit tests without instantiating Flutter UI or Provider contexts.")
    ]

    for q, a in viva_part_b:
        story.append(p(f"<b>{q}</b>", 'Ques'))
        story.append(p(a, 'Ans'))

    story.append(PageBreak())
    story.append(p("<b>PART C: FIREBASE &amp; CLOUD ARCHITECTURE (Q56 - Q80)</b>", 'H2'))

    viva_part_c = [
        ("Q56: What is Firebase and which Firebase services are used in this app?",
         "Firebase is Google's Backend-as-a-Service (BaaS) platform. In this project, we use: 1. Firebase Core (initialization), 2. Firebase Authentication (identity), 3. Cloud Firestore (real-time NoSQL DB), 4. Firebase Cloud Messaging (push notifications)."),
        
        ("Q57: Why is Firebase Storage NOT used in this project?",
         "To strictly comply with the Firebase Spark Plan (Free Tier) and eliminate storage bandwidth costs. Instead, we use external validated HTTPS image URLs cached client-side."),
        
        ("Q58: What is Cloud Firestore and how does it differ from Firebase Realtime Database?",
         "Cloud Firestore is a modern, scalable NoSQL document-oriented database. It organizes data into collections of documents, supports rich subcollections, multi-field querying, automatic indexing, and true ACID transactions, whereas Realtime DB is a single giant JSON tree."),
        
        ("Q59: What is the structure of a Document and Collection in Firestore?",
         "A Collection is a container of Documents. A Document is a set of key-value pairs (supporting strings, numbers, booleans, timestamps, maps, and arrays). Documents can also contain nested Subcollections."),
        
        ("Q60: How does Firestore handle offline persistence?",
         "Firestore client SDK includes built-in offline caching. It caches cloud documents locally on the device, allowing reads and writes while offline, and automatically synchronizes mutations when connectivity is restored."),
        
        ("Q61: How are Firebase Custom Claims used for Role-Based Access Control (RBAC)?",
         "Firebase Auth allows attaching custom attributes (claims) to user tokens on the backend. Our security rules verify 'request.auth.token.admin == true' to grant administrative privileges securely without relying on client-side state."),
        
        ("Q62: Explain Firestore Security Rules and why they are critical.",
         "Firestore security rules execute on Google's servers before any database operation is permitted. They prevent unauthorized client-side tampering, enforce schema invariants, and isolate private user data."),
        
        ("Q63: What does 'request.auth != null' mean in firestore.rules?",
         "It verifies that the incoming request originates from an authenticated user whose JWT token has been validated by Firebase Authentication."),
        
        ("Q64: How does our security rule protect the /recipes collection?",
         "Anyone can read recipes. Admins can create, update, or delete. Regular authenticated users can only update the 'rating', 'review', and 'viewCount' fields via whitelist diff inspection."),
        
        ("Q65: What is a Firestore Transaction ('runTransaction')?",
         "A transaction is an atomic set of read and write operations. If any read data changes concurrently on the server before the write commits, Firestore automatically retries the transaction, preventing race conditions."),
        
        ("Q66: Where do we use 'runTransaction' in our codebase?",
         "In 'ReviewRepository.submitReview()' and 'deleteReview()' to read current aggregate rating and review count, calculate the new average, and write both the review document and updated recipe metrics atomically."),
        
        ("Q67: What is a Firestore Batch Write ('WriteBatch')?",
         "A batch write combines up to 500 set, update, or delete operations into a single atomic request. If one fails, all fail. We use it in 'ShoppingListRepository' to insert all recipe ingredients at once."),
        
        ("Q68: What is the difference between a Transaction and a Batch Write?",
         "A Batch Write is write-only and does not read data. A Transaction reads document state first, computes logic based on that state, and writes updates atomically with concurrency protection."),
        
        ("Q69: What is 'FieldValue.serverTimestamp()' and why is it preferred over DateTime.now()?",
         "It instructs Google's Firestore servers to populate the exact server-side timestamp when the document is written, avoiding inaccuracies from incorrect user device clocks or timezone mismatches."),
        
        ("Q70: What is 'FieldValue.increment(1)'?",
         "An atomic server-side operation that increments a numeric field by a specified value without needing to read the document first. We use it in 'RecipeRepository.incrementViewCount()'."),

        ("Q71: What is the difference between 'set' and 'update' in Firestore?",
         "'set' overwrites the document completely (or merges if SetOptions(merge: true) is passed). 'update' modifies only the specified fields and fails if the document does not already exist."),

        ("Q72: How are compound queries handled in Firestore?",
         "Compound queries filter on multiple fields (e.g. .where('category', isEqualTo: 'Dinner').where('isPublished', isEqualTo: true)). Firestore creates automatic composite indexes when required."),

        ("Q73: What is the maximum size of a single Firestore document?",
         "1 Megabyte (1,048,576 bytes). Our recipe and review documents are lightweight (< 5 KB), well within this limit."),

        ("Q74: How does Firebase Cloud Messaging (FCM) deliver push notifications?",
         "FCM generates a unique registration token per device. When a notification is dispatched, Google servers route the payload to the device's native APNs (iOS) or Play Services (Android)."),

        ("Q75: What is the role of 'firebase_options.dart'?",
         "It contains the generated FirebaseOptions object for each platform (Android, iOS, Web, Windows), mapping the respective API keys, App IDs, and Project IDs.")
    ]

    for q, a in viva_part_c:
        story.append(p(f"<b>{q}</b>", 'Ques'))
        story.append(p(a, 'Ans'))

    story.append(PageBreak())
    story.append(p("<b>PART D: CODEBASE-SPECIFIC &amp; IMPLEMENTATION QUESTIONS (Q76 - Q105)</b>", 'H2'))

    viva_part_d = [
        ("Q76: How does 'Recipe.fromFirestore()' handle backward compatibility with legacy ingredient arrays?",
         "The deserializer checks if 'ingredients' is present as a list of Maps. If missing, it falls back to zipping parallel lists: 'ingredientName', 'ingredientAmount', and 'ingredientImage' into unified 'IngredientItem' objects."),
        
        ("Q77: What is the purpose of 'lib/utils/ingredient_scaler.dart'?",
         "It calculates real-time ingredient amounts when the user adjusts the servings counter (+ / -). It parses fractions like '1/2' or decimals and scales them cleanly without trailing zeros."),
        
        ("Q78: How does 'ImageUrlValidator' protect the application from crashes?",
         "It validates that user-entered image URLs start with 'https://', have a valid URI structure, and point to permitted web image extensions or known CDNs (Unsplash, Cloudinary), rejecting malformed links."),
        
        ("Q79: Explain the implementation of 'SafeNetworkImage'.",
         "SafeNetworkImage is a robust custom image widget that wraps Image.network with a loadingBuilder showing a shimmer skeleton and an errorBuilder displaying a fallback food placeholder icon."),
        
        ("Q80: How does 'CookingTimerWidget' work?",
         "It is a StatefulWidget that uses a Dart 'Timer.periodic(1 second)' to decrement remaining cooking time, updating progress in a CircularProgressIndicator with pause, resume, and reset controls."),
        
        ("Q81: How is dynamic theme switching persisted?",
         "When a user toggles theme in 'AppPreferencesScreen', PreferencesProvider saves the setting to SharedPreferences and writes it to '/users/{uid}/preferences/settings' in Firestore, notifying MaterialApp to switch ThemeData."),
        
        ("Q82: How are user push notification tokens registered in Firestore?",
         "In 'NotificationService', 'FirebaseMessaging.instance.getToken()' retrieves the FCM device token and writes it to '/users/{uid}/notification_tokens/{token}' with a server timestamp."),
        
        ("Q83: How is the 'searchName' field in FoodCategory used?",
         "It stores the category name in lowercase at document creation time, enabling exact and prefix Firestore search queries without requiring expensive regex operations."),
        
        ("Q84: What happens when an Admin deletes a recipe?",
         "AdminRecipesScreen prompts a confirmation dialog. Upon approval, RecipeRepository deletes '/recipes/{recipeId}' from Firestore. Because UI is listening to snapshots, the item vanishes instantly from all clients."),
        
        ("Q85: What automated tests exist for the Admin flow?",
         "In 'test/phase4_admin_test.dart', tests verify that admin custom claims are verified, that unpublished recipes are hidden from audience streams, and that category toggles update correctly."),

        ("Q86: How does 'FavoritesScreen' retrieve only bookmarked recipes?",
         "RecipeProvider maintains a Set<String> 'favoriteIds' synced with '/users/{uid}/favorites'. FavoritesScreen filters the global published recipes list by checking 'favoriteIds.contains(recipe.id)'."),

        ("Q87: How is 'RecentlyViewedScreen' populated?",
         "RecentlyViewedProvider streams '/users/{uid}/recentlyViewed' ordered by 'viewedAt' descending, displaying the last viewed recipes with their snapshot metadata."),

        ("Q88: What happens when a user deletes a review?",
         "In ReviewRepository.deleteReview(), a transaction removes the review document from '/recipes/{id}/reviews', removes the index from '/users/{uid}/reviews', and recalculates the new lower average rating on the recipe."),

        ("Q89: How does 'QuantitySelector' prevent invalid negative servings?",
         "QuantitySelector enforces a minimum boundary (min: 1). If the count reaches 1, the decrement (-) button is automatically disabled."),

        ("Q90: How does 'SearchField' handle real-time search queries?",
         "It triggers 'onChanged' callback on every keystroke, which dispatches 'recipeProvider.setSearchQuery(query)' to update the filtered list instantly."),

        ("Q91: How does 'EditRecipeScreen' pre-populate form values?",
         "When opened with a Recipe object, its State class initializes TextControllers with existing values (title, description, calories, cookTime, servings, ingredients list) inside initState()."),

        ("Q92: How does 'SignupScreen' handle user registration?",
         "It validates name, email, and password form fields, calls 'authProvider.signUp(email, password, name)', and automatically logs the user in upon successful Firebase Auth creation."),

        ("Q93: How does 'MainNavigation' maintain bottom bar tab state?",
         "It is a StatefulWidget that tracks 'currentIndex' and renders an IndexedStack or body widget corresponding to [HomeScreen, FavoritesScreen, ShoppingListScreen, ProfileScreen]."),

        ("Q94: What does 'AppTheme.coralPrimary' define?",
         "It defines the primary brand accent color Color(0xFFFF5A36), used consistently across buttons, active tab indicators, rating stars, and floating action buttons."),

        ("Q95: How does 'CategoryChip' indicate its selected state?",
         "It compares its category name with 'recipeProvider.selectedCategory'. If matched, it renders with coral background and white text; otherwise, it renders with neutral surface color."),

        ("Q96: How does 'ShoppingListItem' model represent completion state?",
         "It has a boolean field 'completed'. When tapped in ShoppingListScreen, ShoppingListProvider toggles the value and updates the Firestore document field 'completed: !item.completed'."),

        ("Q97: How does 'clearCompleted()' in ShoppingListRepository work?",
         "It queries all documents where 'completed == true' under '/users/{uid}/shoppingList' and commits a batch delete to clear only finished items."),

        ("Q98: What happens when Google Sign-In is triggered?",
         "In AuthRepository.signInWithGoogle(), GoogleSignIn prompts the account picker, retrieves GoogleAuth tokens (idToken, accessToken), creates an AuthCredential, and signs into FirebaseAuth."),

        ("Q99: What is the purpose of 'test/phase2_test.dart'?",
         "It tests the full integration of user subcollections: adding items to shopping list, verifying preferences serialization, and recording recently viewed items."),

        ("Q100: What is the purpose of 'test/phase3_test.dart'?",
         "It tests review submission math, ensuring that 5-star reviews correctly increment count and recalculate the arithmetic mean accurately."),

        ("Q101: How is memory management handled in 'RecipeDetailScreen'?",
         "The cooking timer's periodic timer is explicitly cancelled in dispose() to prevent background execution after the user leaves the screen."),

        ("Q102: How does the app handle internet disconnection?",
         "Cloud Firestore's offline cache continues serving previously loaded recipes. If an un-cached network operation fails, 'ErrorView' displays a retry button."),

        ("Q103: How does 'AdminCategoriesScreen' toggle a category's active state?",
         "It calls 'recipeRepository.updateCategory(category.copyWith(isActive: !category.isActive))', updating Firestore in real time."),

        ("Q104: Why is 'flutter_lints' included in dev_dependencies?",
         "To enforce Google's official Dart style guide, catching dead code, un-awaited futures, missing const keywords, and unused imports at compile time."),

        ("Q105: What is the overall architectural strength of this Recipe App?",
         "It combines clean 3-tier modularity, complete role-based security, atomic transaction integrity, and zero-cost serverless optimization under the Firebase Spark Plan.")
    ]

    for q, a in viva_part_d:
        story.append(p(f"<b>{q}</b>", 'Ques'))
        story.append(p(a, 'Ans'))

    # ==========================================
    # SECTION 9: TOP 50 TEACHER MAY ASK THIS
    # ==========================================
    story.append(PageBreak())
    story.append(p("SECTION 9: TOP 50 'TEACHER MAY ASK THIS' HIGH-PROBABILITY VIVA QUESTIONS", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p(
        "These 50 questions are specifically calibrated to the questions university professors and external examiners ask during practical lab defenses. "
        "Each answer points directly to the exact file and architectural mechanism in this codebase:"
    ))

    top_50 = [
        ("T01: Where is Firebase initialized in the codebase?",
         "In <font face='Courier'>lib/main.dart</font> inside <font face='Courier'>main()</font> using <font face='Courier'>await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)</font>."),
        
        ("T02: Show me where you check if a user is an Admin or regular user.",
         "In <font face='Courier'>lib/repositories/auth_repository.dart</font> in method <font face='Courier'>isAdmin()</font>, which calls <font face='Courier'>user.getIdTokenResult()</font> and checks <font face='Courier'>claims?['admin'] == true</font>."),
        
        ("T03: Where is the routing logic between Admin and Audience located?",
         "In <font face='Courier'>lib/main.dart</font> inside the <font face='Courier'>AuthWrapper</font> widget which inspects <font face='Courier'>authProvider.isAdmin</font>."),
        
        ("T04: Where is the Recipe model defined and how does it parse JSON?",
         "In <font face='Courier'>lib/models/recipe.dart</font> inside the factory constructor <font face='Courier'>Recipe.fromFirestore(DocumentSnapshot doc)</font>."),
        
        ("T05: What happens if an image URL in Firestore is invalid or broken?",
         "The custom widget <font face='Courier'>SafeNetworkImage</font> in <font face='Courier'>lib/widgets/safe_network_image.dart</font> intercepts the error via <font face='Courier'>errorBuilder</font> and renders a graceful placeholder icon without crashing."),
        
        ("T06: How do you calculate dynamic ingredient quantities for different servings?",
         "Using <font face='Courier'>IngredientScaler.scaleAmount()</font> in <font face='Courier'>lib/utils/ingredient_scaler.dart</font>, which calculates <font face='Courier'>(targetServings / baseServings) * amount</font>."),
        
        ("T07: Where are Firestore transactions used in the project?",
         "In <font face='Courier'>lib/repositories/review_repository.dart</font> inside <font face='Courier'>submitReview()</font> to calculate the new average rating atomically."),
        
        ("T08: Where are batch writes used in this application?",
         "In <font face='Courier'>lib/repositories/shopping_list_repository.dart</font> inside <font face='Courier'>addItems()</font> and <font face='Courier'>clearCompleted()</font>."),
        
        ("T09: How is dark mode implemented and where does the theme change happen?",
         "In <font face='Courier'>lib/utils/app_theme.dart</font> (theme definitions) and <font face='Courier'>lib/providers/preferences_provider.dart</font> which updates <font face='Courier'>themeMode</font> on <font face='Courier'>MaterialApp</font> in <font face='Courier'>lib/main.dart</font>."),
        
        ("T10: How do you prevent a regular user from writing to the /recipes collection in Firestore?",
         "Through <font face='Courier'>firestore.rules</font> line: <font face='Courier'>allow create, delete: if isAdmin();</font> where <font face='Courier'>isAdmin()</font> checks custom JWT claims."),

        ("T11: Which package is used for icons in this app?",
         "<font face='Courier'>iconsax: ^0.0.8</font> and <font face='Courier'>cupertino_icons: ^1.0.8</font> in <font face='Courier'>pubspec.yaml</font>."),

        ("T12: Where is Google Sign-In implemented?",
         "In <font face='Courier'>lib/repositories/auth_repository.dart</font> in method <font face='Courier'>signInWithGoogle()</font> using the <font face='Courier'>google_sign_in</font> package."),

        ("T13: Where do you store the user's bookmarked favorite recipes?",
         "In Cloud Firestore subcollection <font face='Courier'>/users/{uid}/favorites/{recipeId}</font> managed by <font face='Courier'>RecipeRepository</font>."),

        ("T14: How does the cooking timer update its UI every second?",
         "In <font face='Courier'>lib/widgets/timer_widget.dart</font>, a <font face='Courier'>Timer.periodic(const Duration(seconds: 1))</font> calls <font face='Courier'>setState()</font> to decrement remaining time."),

        ("T15: Where is the code that handles push notifications?",
         "In <font face='Courier'>lib/services/notification_service.dart</font> using <font face='Courier'>firebase_messaging</font>."),

        ("T16: How do you search recipes in real time?",
         "In <font face='Courier'>lib/providers/recipe_provider.dart</font>, the <font face='Courier'>searchQuery</font> state filters the list via <font face='Courier'>filteredRecipes</font> getter on every keystroke in <font face='Courier'>SearchField</font>."),

        ("T17: Why is SharedPreferences used alongside Cloud Firestore?",
         "SharedPreferences provides instantaneous offline reading of theme and serving preferences on cold app boot before Firebase network connection initializes."),

        ("T18: What is the primary color of the application theme?",
         "Coral Orange: <font face='Courier'>Color(0xFFFF5A36)</font> defined in <font face='Courier'>lib/utils/app_theme.dart</font>."),

        ("T19: Where is the admin recipe creation screen located?",
         "In <font face='Courier'>lib/screens/admin/add_recipe_screen.dart</font>."),

        ("T20: How many automated tests are in the test suite?",
         "54 automated tests across 9 test files in the <font face='Courier'>test/</font> directory, all passing with 100% success."),

        ("T21: Where is the category model defined?",
         "In <font face='Courier'>lib/models/food_category.dart</font>."),

        ("T22: How is the average star rating displayed on a recipe card?",
         "Using <font face='Courier'>StarRatingWidget</font> in <font face='Courier'>lib/widgets/rating_widget.dart</font>."),

        ("T23: What does 'isPublished' field do on a recipe?",
         "It acts as a visibility flag: only recipes with <font face='Courier'>isPublished == true</font> are shown in audience streams, allowing admins to draft or hide recipes."),

        ("T24: Where are user reviews displayed for a specific recipe?",
         "On <font face='Courier'>RecipeDetailScreen</font> in <font face='Courier'>lib/screens/recipe_detail_screen.dart</font> consuming <font face='Courier'>ReviewProvider</font>."),

        ("T25: How does a user add ingredients to their shopping list?",
         "By tapping 'Add to Shopping List' on <font face='Courier'>RecipeDetailScreen</font>, which dispatches <font face='Courier'>shoppingListProvider.addRecipeIngredients()</font>."),

        ("T26: How do you validate form fields in Flutter?",
         "Using a 'GlobalKey<FormState>()', wrapping TextFormFields with 'validator: (val) => val == null || val.isEmpty ? \"Error\" : null', and calling 'formKey.currentState!.validate()'."),

        ("T27: What is the difference between 'SingleChildScrollView' and 'ListView'?",
         "'SingleChildScrollView' wraps a single layout widget (like Column) to make it scrollable. 'ListView' is optimized for displaying repeating lists of items, with 'ListView.builder' providing lazy rendering."),

        ("T28: How do you show a SnackBar in Flutter?",
         "Using 'ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(\"Message\")))'."),

        ("T29: How do you navigate to a new screen and remove back stack history?",
         "Using 'Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => NextScreen()), (route) => false)'."),

        ("T30: Where are the mock data JSON files stored?",
         "Under <font face='Courier'>assets/data/</font> declared in <font face='Courier'>pubspec.yaml</font>."),

        ("T31: What is the purpose of 'lib/widgets/state_views.dart'?",
         "It contains reusable standard views: 'LoadingView' (spinner), 'EmptyStateView' (illustrated empty message), and 'ErrorView' (retry button)."),

        ("T32: How is the view count incremented on a recipe?",
         "In <font face='Courier'>lib/repositories/recipe_repository.dart</font> in method <font face='Courier'>incrementViewCount()</font> using <font face='Courier'>FieldValue.increment(1)</font>."),

        ("T33: How does the app ensure non-admin users cannot alter recipe descriptions?",
         "Firestore security rules check <font face='Courier'>affectedKeys().hasOnly(['rating', 'review', 'viewCount'])</font> for regular user updates."),

        ("T34: Where is the shopping list screen implemented?",
         "In <font face='Courier'>lib/screens/shopping_list_screen.dart</font>."),

        ("T35: How do you dismiss the on-screen keyboard programmatically?",
         "Using <font face='Courier'>FocusScope.of(context).unfocus()</font>."),

        ("T36: What is a factory constructor in Dart and where is it used in our app?",
         "A constructor that doesn't always create a new instance of its class. Used in all models (<font face='Courier'>Recipe.fromFirestore()</font>, <font face='Courier'>FoodCategory.fromFirestore()</font>) to deserialize JSON maps into objects."),

        ("T37: What is the purpose of 'lib/models/recently_viewed.dart'?",
         "It defines the data model for browsing history, storing recipe ID, name, image, calories, cook time, and the timestamp when it was viewed."),

        ("T38: How do you handle password reset in Firebase Auth?",
         "In <font face='Courier'>lib/repositories/auth_repository.dart</font> via <font face='Courier'>sendPasswordResetEmail(email)</font>."),

        ("T39: What is the purpose of 'lib/screens/verification_screen.dart'?",
         "It handles email verification reminders for newly signed-up accounts."),

        ("T40: What happens if Firestore returns a null value for a numeric field?",
         "In <font face='Courier'>lib/repositories/review_repository.dart</font> and models, static helper methods <font face='Courier'>_asDouble()</font> and <font face='Courier'>_asInt()</font> safely fallback to 0.0 or 0."),

        ("T41: Where is the user profile screen implemented?",
         "In <font face='Courier'>lib/screens/profile_screen.dart</font>."),

        ("T42: How does the admin toggle whether a recipe is published or draft?",
         "In <font face='Courier'>AdminRecipesScreen</font>, a Switch widget calls <font face='Courier'>recipeRepository.togglePublishStatus(recipeId, isPublished)</font>."),

        ("T43: Where is the admin category list screen located?",
         "In <font face='Courier'>lib/screens/admin/admin_categories_screen.dart</font>."),

        ("T44: How does 'FavoritesScreen' handle empty state?",
         "If <font face='Courier'>favoriteRecipes.isEmpty</font>, it renders <font face='Courier'>EmptyStateView(title: 'No Favorites Yet')</font> prompting the user to explore recipes."),

        ("T45: What is the role of 'lib/screens/popular_recipes_screen.dart'?",
         "It displays a curated list of top recipes sorted by highest <font face='Courier'>viewCount</font>."),

        ("T46: What is the role of 'lib/screens/top_rated_recipes_screen.dart'?",
         "It displays recipes sorted by highest aggregate <font face='Courier'>rating</font>."),

        ("T47: How is user sign-out handled across all providers?",
         "When <font face='Courier'>authProvider.signOut()</font> is called, Firebase Auth terminates the session, triggering <font face='Courier'>authStateChanges()</font> which resets state in AuthWrapper and navigates to LoginScreen."),

        ("T48: What is 'test/recipe_provider_test.dart' verifying?",
         "It tests the business logic of RecipeProvider: category selection, search filtering, and favorite state toggling in memory."),

        ("T49: Why is Flutter cross-platform?",
         "Because Flutter compiles Dart code to native ARM/x86 machine code (for Android/iOS/Windows) or JavaScript/Wasm (for Web), rendering its own UI canvas on any target platform."),

        ("T50: If you had more time, what future enhancements would you add?",
         "1. Offline recipe caching with Hive/Isar for full offline cooking mode. 2. Push notifications for new recipes using Cloud Messaging topics. 3. Social recipe sharing via deep links.")
    ]

    for q, a in top_50:
        story.append(p(f"<b>{q}</b>", 'Ques'))
        story.append(p(a, 'Ans'))

    # ==========================================
    # SECTION 10: PRESENTATION & DEMO STRATEGY
    # ==========================================
    story.append(PageBreak())
    story.append(p("SECTION 10: PRESENTATION &amp; LIVE DEMONSTRATION STRATEGY GUIDE", 'H1'))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceBefore=2, spaceAfter=8))

    story.append(p("<b>10.1 5-Minute High-Impact Presentation Script</b>", 'H2'))
    story.append(p(
        "<b>Introduction (1 min):</b> 'Good morning respected faculty and examiner. My name is Sourav Debnath (ID: 22CSE009). "
        "Today, I am presenting my Flutter and Firebase Recipe Application. The objective of this project is to build a high-performance, cross-platform recipe discovery and meal management application that operates entirely on Firebase's free Spark tier without costly cloud storage or backend functions.'"
    ))
    story.append(p(
        "<b>Architecture &amp; Core Technical Value (2 mins):</b> 'The app is built on a 3-tier Clean Layered Architecture: UI Presentation, ChangeNotifier Provider state management, and Firestore Repositories. "
        "We implement Role-Based Access Control via Firebase Custom Claims to segregate Admin content management from Audience discovery. "
        "Key highlights include client-side arithmetic serving scaling, atomic Firestore transactions for multi-user reviews, and zero-cost HTTPS image caching.'"
    ))
    story.append(p(
        "<b>Live Demo &amp; Conclusion (2 mins):</b> 'I will now demonstrate logging in as an Admin, publishing a new recipe, and instantly witnessing the real-time stream update on the Audience client, scaling ingredient portions from 2 to 6 servings, adding them to the shopping list, and toggling dark theme.'"
    ))

    story.append(p("<b>10.2 Step-by-Step Live Demo Checklist</b>", 'H2'))
    story.append(p(
        "1. <b>Auth &amp; RBAC Demo:</b> Show Login screen -> Log in with Audience account -> Demonstrate bottom navigation (Home, Favorites, Shopping List, Profile).<br/>"
        "2. <b>Recipe Discovery &amp; Search:</b> Tap category chips (Breakfast, Dinner) -> Type into search field -> Observe instantaneous reactive list filtering.<br/>"
        "3. <b>Recipe Detail &amp; Scaler:</b> Open recipe -> Tap '+' on Servings -> Show ingredients updating in real time -> Tap 'Add to Shopping List' -> Navigate to Shopping List to show batch added items.<br/>"
        "4. <b>Interactive Cooking Timer:</b> Start timer -> Show animated circular countdown -> Pause &amp; Reset.<br/>"
        "5. <b>Ratings &amp; Reviews:</b> Submit a 5-star rating -> Show atomic rating calculation updating the aggregate average.<br/>"
        "6. <b>Admin Dashboard:</b> Log out -> Sign in with Admin account -> Open Admin Dashboard -> Demonstrate Recipe and Category CRUD with HTTPS image preview."
    ))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generated successfully: {filename}")

if __name__ == "__main__":
    target_root = r"e:\mobile app\projects\recipe App\Recipe_App_Project_Documentation_and_Viva_Handbook.pdf"
    target_docs = r"e:\mobile app\projects\recipe App\docs\Recipe_App_Project_Documentation_and_Viva_Handbook.pdf"

    build_pdf(target_root)
    shutil.copyfile(target_root, target_docs)
    print(f"Copied to docs: {target_docs}")
