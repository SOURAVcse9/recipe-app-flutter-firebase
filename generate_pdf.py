import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image as RLImage, Table, TableStyle, PageBreak, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont('Helvetica', 8)
        self.setFillColor(colors.HexColor('#718096'))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(36, A4[1] - 24, 'Flutter Recipe App — System Architecture & Visual Walkthrough')
            self.drawRightString(A4[0] - 36, A4[1] - 24, 'Production Documentation')
            self.setStrokeColor(colors.HexColor('#CBD5E0'))
            self.setLineWidth(0.6)
            self.line(36, A4[1] - 28, A4[0] - 36, A4[1] - 28)
        
        # Footer
        self.setStrokeColor(colors.HexColor('#CBD5E0'))
        self.setLineWidth(0.6)
        self.line(36, 28, A4[0] - 36, 28)
        
        self.drawString(36, 16, 'GitHub: SOURAVcse9/recipe-app-flutter-firebase | Flutter 3.22+ & Firebase')
        self.drawRightString(A4[0] - 36, 16, f'Page {self._pageNumber} of {page_count}')
        self.restoreState()

def create_pdf(filename='docs/Recipe_App_Architecture_and_Visual_Walkthrough.pdf'):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=34,
        bottomMargin=34
    )
    
    styles = getSampleStyleSheet()
    
    c_primary = colors.HexColor('#FF5A36')
    c_dark = colors.HexColor('#1A202C')
    c_slate = colors.HexColor('#2D3748')
    c_gray = colors.HexColor('#4A5568')
    c_light_bg = colors.HexColor('#F7FAFC')
    c_border = colors.HexColor('#E2E8F0')
    
    title_style = ParagraphStyle(
        'CoverTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=21,
        textColor=c_dark
    )
    
    subtitle_style = ParagraphStyle(
        'CoverSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12,
        textColor=c_gray
    )
    
    section_h1 = ParagraphStyle(
        'SectionH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=14,
        textColor=c_dark,
        spaceBefore=2,
        spaceAfter=2
    )
    
    figure_title_style = ParagraphStyle(
        'FigTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=10.5,
        textColor=c_primary
    )
    
    figure_desc_style = ParagraphStyle(
        'FigDesc',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.2,
        leading=9.5,
        textColor=c_slate
    )
    
    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.8,
        leading=10.8,
        textColor=c_slate
    )
    
    table_text_bold = ParagraphStyle(
        'TableBold',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=c_dark
    )
    
    table_text_normal = ParagraphStyle(
        'TableNormal',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7,
        leading=9,
        textColor=c_slate
    )

    story = []
    page_w = A4[0] - 72 # 523.27 pt
    
    # -------------------------------------------------------------
    # PAGE 1: HERO & ARCHITECTURE OVERVIEW
    # -------------------------------------------------------------
    header_table_data = [
        [
            Paragraph('<b>Flutter + Firebase Recipe App</b>', title_style),
            Paragraph('<font color="#FF5A36"><b>v1.0.0 Production</b></font><br/><font size=7 color="#718096">Spark Tier Architecture</font>', ParagraphStyle('RightH', parent=styles['Normal'], alignment=2, leading=9.5))
        ],
        [
            Paragraph('System Architecture, Admin Cloud Mechanics & Audience Visual Walkthrough', subtitle_style),
            Paragraph('<font size=7 color="#4A5568">Author: <b>SOURAV DEBNATH</b><br/>Repo: <b>SOURAVcse9/recipe-app-flutter-firebase</b></font>', ParagraphStyle('RightM', parent=styles['Normal'], alignment=2, leading=9))
        ]
    ]
    header_table = Table(header_table_data, colWidths=[page_w * 0.65, page_w * 0.35])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1),
        ('TOPPADDING', (0,0), (-1,-1), 0),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 4))
    
    summary_html = (
        '<b>Executive Overview:</b> A production-grade, cross-platform mobile recipe discovery and meal management application '
        'built with <b>Flutter 3.22+</b>, <b>Firebase Cloud Firestore</b>, and <b>Provider</b> state management. '
        'Engineered strictly for Firebase Spark Plan efficiency without Firebase Storage or Cloud Functions dependencies, '
        'featuring real-time reactive streams, external HTTPS image delivery, role-based admin controls, and dynamic local state engines.'
    )
    summary_box = Table([[Paragraph(summary_html, body_style)]], colWidths=[page_w])
    summary_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), c_light_bg),
        ('BOX', (0,0), (-1,-1), 0.8, c_border),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(summary_box)
    story.append(Spacer(1, 6))
    
    def make_image_card(img_path, width, height, fig_num, fig_title, fig_desc):
        img_flowable = RLImage(img_path, width=width, height=height)
        caption = [
            Paragraph(f'<b>Figure {fig_num}: {fig_title}</b>', figure_title_style),
            Spacer(1, 1),
            Paragraph(fig_desc, figure_desc_style)
        ]
        card_table = Table([[img_flowable], [caption]], colWidths=[width + 8])
        card_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.white),
            ('BOX', (0,0), (-1,-1), 0.6, c_border),
            ('LEFTPADDING', (0,0), (-1,-1), 4),
            ('RIGHTPADDING', (0,0), (-1,-1), 4),
            ('TOPPADDING', (0,0), (-1,-1), 3),
            ('BOTTOMPADDING', (0,0), (-1,-1), 3),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ]))
        return card_table

    def make_dual_image_card(img1_path, img2_path, w, h, fig_num, fig_title, fig_desc):
        img1 = RLImage(img1_path, width=w, height=h)
        img2 = RLImage(img2_path, width=w, height=h)
        inner_table = Table([[img1, img2]], colWidths=[w, w])
        inner_table.setStyle(TableStyle([
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('LEFTPADDING', (0,0), (-1,-1), 2),
            ('RIGHTPADDING', (0,0), (-1,-1), 2),
            ('TOPPADDING', (0,0), (-1,-1), 0),
            ('BOTTOMPADDING', (0,0), (-1,-1), 0),
        ]))
        
        caption = [
            Paragraph(f'<b>Figure {fig_num}: {fig_title}</b>', figure_title_style),
            Spacer(1, 1),
            Paragraph(fig_desc, figure_desc_style)
        ]
        
        card_table = Table([[inner_table], [caption]], colWidths=[page_w])
        card_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.white),
            ('BOX', (0,0), (-1,-1), 0.6, c_border),
            ('LEFTPADDING', (0,0), (-1,-1), 6),
            ('RIGHTPADDING', (0,0), (-1,-1), 6),
            ('TOPPADDING', (0,0), (-1,-1), 3),
            ('BOTTOMPADDING', (0,0), (-1,-1), 3),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ]))
        return card_table

    # 1. ARCHITECTURE & ADMIN BACKEND
    story.append(Paragraph('1. System Architecture & Admin Cloud Backend', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.2, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    # Figure 1
    fig1 = make_image_card(
        'docs/images/slide_page_1.png',
        width=page_w - 10,
        height=(page_w - 10) / 1.82,
        fig_num='1',
        fig_title='Full-Stack System Design & State Propagation Flow',
        fig_desc='Architectural blueprint showing Cloud Firestore collections, Provider state hydration, and reactive UI binding in Flutter.'
    )
    story.append(fig1)
    story.append(Spacer(1, 6))
    
    # Figure 2
    fig2 = make_dual_image_card(
        'docs/images/admin_firestore_database.png',
        'docs/images/admin_firestore_schema.png',
        w=(page_w - 18) / 2,
        h=((page_w - 18) / 2) / 1.84,
        fig_num='2',
        fig_title='Cloud Firestore Database Hierarchy & Document Schemas',
        fig_desc='Live Firestore structure showing normalized collections (/categories, /recipes, /users) and structured recipe documents with validated HTTPS URLs.'
    )
    story.append(fig2)
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 2: INFRASTRUCTURE, SCHEMA & ADMIN LOOP
    # -------------------------------------------------------------
    # Figure 3
    fig3 = make_dual_image_card(
        'docs/images/slide_page_3.png',
        'docs/images/slide_page_4.png',
        w=(page_w - 18) / 2,
        h=((page_w - 18) / 2) / 1.79,
        fig_num='3',
        fig_title='Core Infrastructure Matrix & Dependency Node Tree',
        fig_desc='Left: Division of responsibilities across UI rendering (Flutter), Persistence (Firestore), and State Management (Provider). Right: Minimalist package architecture avoiding bloat.'
    )
    story.append(fig3)
    story.append(Spacer(1, 6))
    
    # Figure 4
    fig4 = make_dual_image_card(
        'docs/images/slide_page_5.png',
        'docs/images/slide_page_6.png',
        w=(page_w - 18) / 2,
        h=((page_w - 18) / 2) / 1.79,
        fig_num='4',
        fig_title='Recipe Document Schema & Parallel Array Mapping',
        fig_desc='Left: Structured NoSQL document fields enforcing schema consistency. Right: Parallel array mapping linking ingredient names, quantities, and external image URLs by strict index positions.'
    )
    story.append(fig4)
    story.append(Spacer(1, 6))
    
    # Figure 5
    fig5 = make_dual_image_card(
        'docs/images/slide_page_9.png',
        'docs/images/slide_page_10.png',
        w=(page_w - 18) / 2,
        h=((page_w - 18) / 2) / 1.79,
        fig_num='5',
        fig_title='Admin Real-Time Hydration & State Persistence Cycle',
        fig_desc='Left: Instant backend-to-frontend synchronization where catalog updates reflect immediately on all client devices. Right: Closed-loop architecture for user actions and remote sync.'
    )
    story.append(fig5)
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 3: AUDIENCE USER EXPERIENCE
    # -------------------------------------------------------------
    story.append(Paragraph('2. Audience User Experience & Visual Interface', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.2, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    # Figure 6: Light vs Dark Home Screen
    fig6 = make_dual_image_card(
        'docs/images/audience_home_light.png',
        'docs/images/audience_home_dark.png',
        w=145,
        h=145 / 0.64,
        fig_num='6',
        fig_title='Interactive Home Discovery Screen (Adaptive Light & Dark Themes)',
        fig_desc='Audience discovery screen showcasing search bar, dynamic category chips, real-time recipe cards with calories, prep time, star ratings, and one-tap favorite toggling.'
    )
    story.append(fig6)
    story.append(Spacer(1, 6))
    
    # Figure 7: Category Filtering & Finished Experience
    fig7 = make_dual_image_card(
        'docs/images/audience_category_filter.png',
        'docs/images/slide_page_2.png',
        w=(page_w - 18) / 2,
        h=((page_w - 18) / 2) / 1.25,
        fig_num='7',
        fig_title='Dynamic Category Filtering & Finished Application Experience',
        fig_desc='Left: Instant category selection filtering live recipe streams. Right: Complete cross-screen interaction model spanning Home, Detail View, and User Favorites.'
    )
    story.append(fig7)
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 4: SCALING, FAVORITES & USER DASHBOARD
    # -------------------------------------------------------------
    # Figure 8: Dynamic Serving Scaling & Persistence
    fig8 = make_dual_image_card(
        'docs/images/slide_page_7.png',
        'docs/images/slide_page_8.png',
        w=(page_w - 18) / 2,
        h=((page_w - 18) / 2) / 1.79,
        fig_num='8',
        fig_title='Dynamic Serving Multiplier Algorithm & State Persistence',
        fig_desc='Left: Mathematical scaling engine adjusting ingredient amounts in real-time when servings change. Right: Cloud-persisted state ensuring favorite meals survive app restarts.'
    )
    story.append(fig8)
    story.append(Spacer(1, 6))
    
    # Figure 9: Favorites & Verified User Profile
    fig9 = make_dual_image_card(
        'docs/images/audience_favorites_dark.png',
        'docs/images/audience_profile_verified.png',
        w=135,
        h=135 / 0.54,
        fig_num='9',
        fig_title='Synchronized Favorites & Verified User Profile Dashboard',
        fig_desc='Left: Real-time user favorites feed. Right: Complete profile management hub displaying verified Google Account status, navigation shortcuts for reviews, shopping lists, and preferences.'
    )
    story.append(fig9)
    story.append(Spacer(1, 6))
    
    # Figure 10: Dark Profile & About App
    fig10 = make_dual_image_card(
        'docs/images/audience_profile_dark.png',
        'docs/images/audience_about_app.png',
        w=135,
        h=135 / 0.63,
        fig_num='10',
        fig_title='Dark Mode Profile Navigation & About Application Specifications',
        fig_desc='Left: Minimalist dark profile options. Right: In-app technical specifications, feature summary, and version metadata.'
    )
    story.append(fig10)
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 5: SPECIFICATIONS & QUALITY AUDIT MATRIX
    # -------------------------------------------------------------
    story.append(Paragraph('3. Technical Specifications & Quality Audit Matrix', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.2, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    spec_table_data = [
        [Paragraph('<b>Component / Area</b>', table_text_bold), Paragraph('<b>Production Implementation Details</b>', table_text_bold), Paragraph('<b>Status</b>', table_text_bold)],
        [
            Paragraph('<b>Framework & SDK</b>', table_text_normal),
            Paragraph('Flutter 3.22+ with Dart 3 null-safety; responsive Android/Web/Windows layout', table_text_normal),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>State Management</b>', table_text_normal),
            Paragraph('Provider with decoupled RecipeProvider, AuthProvider, PreferencesProvider', table_text_normal),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>Cloud Database</b>', table_text_normal),
            Paragraph('Cloud Firestore real-time streams with offline cache enabled (Spark Plan compatible)', table_text_normal),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>Image Architecture</b>', table_text_normal),
            Paragraph('Validated external HTTPS URLs; zero Firebase Storage dependency; zero cost', table_text_normal),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>Security & Roles</b>', table_text_normal),
            Paragraph('Public recipe reading for audience; Admin custom claim required for write operations', table_text_normal),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>User Data Isolation</b>', table_text_normal),
            Paragraph('Subcollections (/users/{uid}/*) strictly isolated to authenticated user ID', table_text_normal),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>Automated Tests</b>', table_text_normal),
            Paragraph('54 unit and widget tests passing across models, providers, and navigation', table_text_normal),
            Paragraph('<font color="green"><b>54 / 54 PASS</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>Static Code Analysis</b>', table_text_normal),
            Paragraph('flutter analyze reports zero errors, zero warnings, and zero linter issues', table_text_normal),
            Paragraph('<font color="green"><b>0 ISSUES</b></font>', table_text_normal)
        ],
        [
            Paragraph('<b>Release Artifact</b>', table_text_normal),
            Paragraph('Android release APK compiled and available in release/app-release.apk (52.3 MB)', table_text_normal),
            Paragraph('<font color="green"><b>READY</b></font>', table_text_normal)
        ],
    ]
    
    spec_table = Table(spec_table_data, colWidths=[page_w * 0.25, page_w * 0.57, page_w * 0.18])
    spec_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#EDF2F7')),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(spec_table)
    story.append(Spacer(1, 6))
    
    # Figure 11: Architecture Synthesis
    fig11 = make_image_card(
        'docs/images/slide_page_11.png',
        width=page_w - 10,
        height=(page_w - 10) / 1.82,
        fig_num='11',
        fig_title='System Engineering Synthesis — Building Systems, Not Just Screens',
        fig_desc='Summary of system mechanics: schema-driven UI structure, Provider computational engine, and Cloud Firestore persistence delivering an enterprise-ready recipe platform.'
    )
    story.append(fig11)
    story.append(Spacer(1, 6))
    
    # Footer Box with Links
    links_html = (
        '<b>Repository & Distribution:</b><br/>'
        '• <b>GitHub Repository:</b> <font color="#3182CE">https://github.com/SOURAVcse9/recipe-app-flutter-firebase</font><br/>'
        '• <b>Production Release APK:</b> <font color="#3182CE">release/app-release.apk</font><br/>'
        '• <b>License:</b> MIT License | Created by <b>Sourav Debnath</b>'
    )
    links_box = Table([[Paragraph(links_html, body_style)]], colWidths=[page_w])
    links_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), c_light_bg),
        ('BOX', (0,0), (-1,-1), 0.8, c_border),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(links_box)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f'Successfully generated PDF: {filename}')

if __name__ == '__main__':
    create_pdf()
