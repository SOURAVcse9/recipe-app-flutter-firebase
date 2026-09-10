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
            self.drawString(36, A4[1] - 22, 'Flutter Recipe App — App Screenshots & Feature Walkthrough')
            self.drawRightString(A4[0] - 36, A4[1] - 22, 'Visual Documentation')
            self.setStrokeColor(colors.HexColor('#CBD5E0'))
            self.setLineWidth(0.5)
            self.line(36, A4[1] - 26, A4[0] - 36, A4[1] - 26)
        
        # Footer
        self.setStrokeColor(colors.HexColor('#CBD5E0'))
        self.setLineWidth(0.5)
        self.line(36, 26, A4[0] - 36, 26)
        
        self.drawString(36, 14, 'GitHub: SOURAVcse9/recipe-app-flutter-firebase | Flutter 3.22+ & Firebase')
        self.drawRightString(A4[0] - 36, 14, f'Page {self._pageNumber} of {page_count}')
        self.restoreState()

def create_pdf(filename='docs/Recipe_App_Screenshots_and_Walkthrough.pdf'):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=30,
        bottomMargin=30
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
        fontSize=16,
        leading=19,
        textColor=c_dark
    )
    
    subtitle_style = ParagraphStyle(
        'CoverSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11,
        textColor=c_gray
    )
    
    section_h1 = ParagraphStyle(
        'SectionH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=13,
        textColor=c_dark,
        spaceBefore=1,
        spaceAfter=1
    )
    
    figure_title_style = ParagraphStyle(
        'FigTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=c_primary
    )
    
    figure_desc_style = ParagraphStyle(
        'FigDesc',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7,
        leading=9,
        textColor=c_slate
    )
    
    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=10,
        textColor=c_slate
    )

    story = []
    page_w = A4[0] - 72 # 523.27 pt
    
    # Hero Header (Page 1 only)
    header_table_data = [
        [
            Paragraph('<b>Flutter + Firebase Recipe App</b>', title_style),
            Paragraph('<font color="#FF5A36"><b>Visual Walkthrough</b></font><br/><font size=6.5 color="#718096">Real App Screenshots</font>', ParagraphStyle('RightH', parent=styles['Normal'], alignment=2, leading=9))
        ],
        [
            Paragraph('Step-by-Step Feature Walkthrough: Admin Management & Audience Experience', subtitle_style),
            Paragraph('<font size=6.5 color="#4A5568">Author: <b>SOURAV DEBNATH</b><br/>Repo: <b>SOURAVcse9/recipe-app-flutter-firebase</b></font>', ParagraphStyle('RightM', parent=styles['Normal'], alignment=2, leading=8.5))
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
    story.append(Spacer(1, 3))
    
    summary_html = (
        '<b>About This Document:</b> This visual walkthrough presents the actual user interfaces and workflows of the Recipe App. '
        'Organized into <b>Admin Management</b> (catalog operations, statistics, HTTPS URL integration) followed by the <b>Audience Experience</b> '
        '(discovery, live category filtering, dynamic scaling, cloud favorites, shopping list, and reviews).'
    )
    summary_box = Table([[Paragraph(summary_html, body_style)]], colWidths=[page_w])
    summary_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), c_light_bg),
        ('BOX', (0,0), (-1,-1), 0.6, c_border),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(summary_box)
    story.append(Spacer(1, 4))
    
    # Helper for dual screenshot cards
    def make_dual_shot_card(img1_path, title1, desc1, fig1_num, img2_path, title2, desc2, fig2_num, w=130, h=275):
        i1 = RLImage(img1_path, width=w, height=h)
        i2 = RLImage(img2_path, width=w, height=h)
        
        cap1 = [
            Paragraph(f'<b>Figure {fig1_num}: {title1}</b>', figure_title_style),
            Spacer(1, 1),
            Paragraph(desc1, figure_desc_style)
        ]
        cap2 = [
            Paragraph(f'<b>Figure {fig2_num}: {title2}</b>', figure_title_style),
            Spacer(1, 1),
            Paragraph(desc2, figure_desc_style)
        ]
        
        col_w = (page_w - 10) / 2
        
        card1 = Table([[i1], [cap1]], colWidths=[col_w])
        card1.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.white),
            ('BOX', (0,0), (-1,-1), 0.5, c_border),
            ('LEFTPADDING', (0,0), (-1,-1), 4),
            ('RIGHTPADDING', (0,0), (-1,-1), 4),
            ('TOPPADDING', (0,0), (-1,-1), 3),
            ('BOTTOMPADDING', (0,0), (-1,-1), 3),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ]))
        
        card2 = Table([[i2], [cap2]], colWidths=[col_w])
        card2.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.white),
            ('BOX', (0,0), (-1,-1), 0.5, c_border),
            ('LEFTPADDING', (0,0), (-1,-1), 4),
            ('RIGHTPADDING', (0,0), (-1,-1), 4),
            ('TOPPADDING', (0,0), (-1,-1), 3),
            ('BOTTOMPADDING', (0,0), (-1,-1), 3),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ]))
        
        outer = Table([[card1, card2]], colWidths=[col_w, col_w])
        outer.setStyle(TableStyle([
            ('LEFTPADDING', (0,0), (-1,-1), 0),
            ('RIGHTPADDING', (0,0), (-1,-1), 0),
            ('TOPPADDING', (0,0), (-1,-1), 0),
            ('BOTTOMPADDING', (0,0), (-1,-1), 0),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ]))
        return outer

    # -------------------------------------------------------------
    # PAGE 1: ADMIN - AUTH & CREATION (Figures 1 to 4)
    # -------------------------------------------------------------
    story.append(Paragraph('1. Authentication & Admin Operations', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.0, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    # Figures 1 & 2
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-37-48.jpg',
        'Authentication & Login Screen',
        'Secure Firebase Auth supporting email/password and Google Sign-In.',
        '1',
        'images/photo_2026-09-10_22-38-14.jpg',
        'Admin Dashboard & Statistics',
        'Overview of published recipes, active categories, and quick management actions.',
        '2',
        w=125, h=255
    ))
    story.append(Spacer(1, 4))
    
    # Figures 3 & 4
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-38-18.jpg',
        'Add Category (HTTPS URL)',
        'Category creator with live HTTPS image URL preview and visibility toggle.',
        '3',
        'images/photo_2026-09-10_22-38-23.jpg',
        'Add Recipe (Multi-Field Form)',
        'Recipe editor with HTTPS image, calories, time, ingredients, and steps.',
        '4',
        w=125, h=255
    ))
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 2: ADMIN PROFILE & AUDIENCE DISCOVERY (Figures 5 to 8)
    # -------------------------------------------------------------
    story.append(Paragraph('2. Admin Shortcut & Audience Home Discovery', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.0, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    # Figures 5 & 6
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-38-28.jpg',
        'Admin Profile & Shortcut Banner',
        'Profile with special top banner shortcut to access Admin Dashboard.',
        '5',
        'images/photo_2026-09-10_22-38-31.jpg',
        'Home — Top Rated & Popular',
        'Discovery feed with curated carousels for Top Rated and Popular recipes.',
        '6',
        w=128, h=270
    ))
    story.append(Spacer(1, 5))
    
    # Figures 7 & 8
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-38-35.jpg',
        'Breakfast Category Feed',
        'Real-time Firestore stream filtered by Breakfast category.',
        '7',
        'images/photo_2026-09-10_22-38-43.jpg',
        'Vegetables Category Feed',
        'Category filtering showcasing healthy meals with calorie and time indicators.',
        '8',
        w=128, h=270
    ))
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 3: FAVORITES, PROFILE & RECIPE DETAILS (Figures 9 to 12)
    # -------------------------------------------------------------
    story.append(Paragraph('3. User Favorites, Profile Hub & Recipe Detail View', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.0, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    # Figures 9 & 10
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-38-47.jpg',
        'Synchronized Favorites Screen',
        'Cloud-synced bookmarks allowing users to access favorite recipes anywhere.',
        '9',
        'images/photo_2026-09-10_22-38-50.jpg',
        'Audience User Profile Hub',
        'Standard user profile displaying Google verification badge and settings.',
        '10',
        w=128, h=270
    ))
    story.append(Spacer(1, 5))
    
    # Figures 11 & 12
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-38-55.jpg',
        'Recipe Detail & Serving Scaler',
        'Nutritional info, rating, and dynamic +/- serving multiplier algorithm.',
        '11',
        'images/photo_2026-09-10_22-38-58.jpg',
        'Cooking Steps, Timer & Reviews',
        'Step-by-step instructions, Shopping list button, timer, and review form.',
        '12',
        w=128, h=270
    ))
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 4: PREFERENCES & PRODUCTIVITY TOOLS (Figures 13 to 16)
    # -------------------------------------------------------------
    story.append(Paragraph('4. App Preferences, Profile Editing & User Productivity', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.0, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    # Figures 13 & 14
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-39-03.jpg',
        'App Preferences & Themes',
        'Theme Mode selection (Light/Dark/System) and default serving configuration.',
        '13',
        'images/photo_2026-09-10_22-39-06.jpg',
        'Edit User Profile Screen',
        'User display name customization persisted directly to Cloud Firestore.',
        '14',
        w=128, h=270
    ))
    story.append(Spacer(1, 5))
    
    # Figures 15 & 16
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-39-10.jpg',
        'Recently Viewed History',
        'Local history tracker recording recently inspected recipes.',
        '15',
        'images/photo_2026-09-10_22-39-14.jpg',
        'Smart Shopping List Checklist',
        'Interactive grocery checklist populated from recipes with delete actions.',
        '16',
        w=128, h=270
    ))
    
    story.append(PageBreak())
    
    # -------------------------------------------------------------
    # PAGE 5: NOTIFICATIONS, REVIEWS & PROJECT SUMMARY (Figures 17 to 18)
    # -------------------------------------------------------------
    story.append(Paragraph('5. Notifications, User Reviews & Technical Summary', section_h1))
    story.append(HRFlowable(width='100%', thickness=1.0, color=c_primary, spaceAfter=4, spaceBefore=1))
    
    # Figures 17 & 18
    story.append(make_dual_shot_card(
        'images/photo_2026-09-10_22-39-18.jpg',
        'Push Notifications Settings',
        'Notification preference toggles for recommendations, new recipes, and reminders.',
        '17',
        'images/photo_2026-09-10_22-39-21.jpg',
        'My Reviews & Ratings History',
        'Personal reviews management hub showing all user-submitted ratings.',
        '18',
        w=130, h=280
    ))
    story.append(Spacer(1, 10))
    
    # Technical Architecture Table
    spec_table_data = [
        [Paragraph('<b>Feature / Component</b>', ParagraphStyle('TH', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=7.5, textColor=c_dark)),
         Paragraph('<b>Implementation Detail</b>', ParagraphStyle('TH', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=7.5, textColor=c_dark)),
         Paragraph('<b>Status</b>', ParagraphStyle('TH', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=7.5, textColor=c_dark))],
        [
            Paragraph('<b>Role-Based Access</b>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('Admin (Custom Claims) can create/edit; Audience has public read access', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7))
        ],
        [
            Paragraph('<b>Cloud Persistence</b>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('Firebase Cloud Firestore with real-time snapshot streams & offline cache', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7))
        ],
        [
            Paragraph('<b>Image Delivery</b>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('External HTTPS URL validation with zero Firebase Storage cost (Spark Plan)', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('<font color="green"><b>VERIFIED</b></font>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7))
        ],
        [
            Paragraph('<b>Automated Tests</b>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('54 automated unit, model, and navigation widget tests passing', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7, textColor=c_slate)),
            Paragraph('<font color="green"><b>54 / 54 PASS</b></font>', ParagraphStyle('TB', parent=styles['Normal'], fontName='Helvetica', fontSize=7))
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
    story.append(Spacer(1, 8))
    
    # Project Links Box
    links_html = (
        '<b>Distribution & Source:</b><br/>'
        '• <b>GitHub Repository:</b> <font color="#3182CE">https://github.com/SOURAVcse9/recipe-app-flutter-firebase</font><br/>'
        '• <b>Production Release APK:</b> <font color="#3182CE">release/app-release.apk (52.3 MB)</font><br/>'
        '• <b>Author:</b> Sourav Debnath (SOURAVcse9) | License: MIT'
    )
    links_box = Table([[Paragraph(links_html, body_style)]], colWidths=[page_w])
    links_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), c_light_bg),
        ('BOX', (0,0), (-1,-1), 0.6, c_border),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(links_box)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f'Successfully generated PDF: {filename}')

if __name__ == '__main__':
    create_pdf()
