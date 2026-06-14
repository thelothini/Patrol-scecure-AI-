// PatrolSecure - Web App Main controller
const app = {
  // API Configuration
  apiUrl: 'https://web-production-f7a33.up.railway.app',
  simulatorMode: false,

  // App State
  state: {
    activeView: 'splash-view',
    activePanel: 'home-panel',
    teacher: null, // Logged in teacher details
    reports: [],
    accessRequests: [],
    loginHistory: [],
    notifications: [
      { id: '1', title: 'Unknown Device Login Attempt', message: 'Login attempted from an unregistered device for teacher@college.edu', type: 'alert', time: new Date(Date.now() - 2 * 3600000), isRead: false },
      { id: '2', title: 'New Patrol Report', message: 'Dr. Priya Sharma submitted a new report for student 22CS001', type: 'info', time: new Date(Date.now() - 3 * 3600000), isRead: false },
      { id: '3', title: 'Repeated Violation Alert', message: 'Student 22CS001 (Arjun Kumar) has 3 reports this month — escalation recommended', type: 'warning', time: new Date(Date.now() - 5 * 3600000), isRead: false },
      { id: '4', title: 'New Patrol Report', message: 'Prof. Karthik Raj submitted a report for student 22EC045 — Mobile Usage in Library', type: 'info', time: new Date(Date.now() - 6 * 3600000), isRead: true }
    ],
    selectedIssueType: null,
    gps: { latitude: null, longitude: null, status: 'loading' },
    reportsTabFilter: 'all',
    selectedReport: null,
    editingProfile: false
  },

  // Mock database for Simulator mode
  mockDb: {
    teachers: [
      { id: 1, name: 'Dr. Priya Sharma', teacherId: 'T1001', email: 'teacher@college.edu', phone: '9876543210', department: 'CSE', deviceName: 'Chrome (Windows 11)', role: 'teacher' },
      { id: 2, name: 'Admin Administrator', teacherId: 'ADM01', email: 'admin@college.edu', phone: '9000000001', department: 'IT', deviceName: 'Chrome (macOS)', role: 'admin' }
    ],
    reports: [
      { id: 101, student_name: 'Arjun Kumar', register_number: '22CS001', department: 'CSE', year_section: 'III - A', issue_type: 'Late Coming', location: 'Block A - Corridor', remarks: 'Arrived 15 minutes late without a valid gate pass.', reported_by: 'T1001', teacher_name: 'Dr. Priya Sharma', date_time: '2026-06-11T08:30', status: 'Open' },
      { id: 102, student_name: 'Sneha Reddy', register_number: '22EC045', department: 'ECE', year_section: 'III - B', issue_type: 'Mobile Usage', location: 'Central Library', remarks: 'Using smartphone during silence hours despite warnings.', reported_by: 'T1002', teacher_name: 'Prof. Karthik Raj', date_time: '2026-06-10T11:15', status: 'Open' },
      { id: 103, student_name: 'Rahul Verma', register_number: '21ME104', department: 'MECH', year_section: 'IV - A', issue_type: 'ID Card Missing', location: 'Main Gate Entrance', remarks: 'Did not wear ID card at gate. Refused to sign register initially.', reported_by: 'T1001', teacher_name: 'Dr. Priya Sharma', date_time: '2026-06-09T09:00', status: 'Resolved' },
      { id: 104, student_name: 'Aditya Sen', register_number: '23CS182', department: 'CSE', year_section: 'I - B', issue_type: 'Uniform Issue', location: 'Block B - Lab Lobby', remarks: 'Wearing non-approved footwear and un-tucked uniform shirt.', reported_by: 'T1004', teacher_name: 'Dr. Priya Sharma', date_time: '2026-06-08T14:45', status: 'Open' }
    ],
    accessRequests: [
      { id: 1, email: 'prof.smith@college.edu', device_name: 'Safari (iPhone 15)', request_time: '2026-06-11 10:20 AM', status: 'Pending' },
      { id: 2, email: 'dr.kumar@college.edu', device_name: 'Edge (Windows 11)', request_time: '2026-06-10 02:40 PM', status: 'Approved' },
      { id: 3, email: 'teacher.dev@college.edu', device_name: 'Chrome (Android 14)', request_time: '2026-06-09 11:10 AM', status: 'Rejected' }
    ],
    loginHistory: [
      { id: 1, teacher_id: 'T1001', teacher_name: 'Dr. Priya Sharma', email: 'teacher@college.edu', device_name: 'Chrome (Windows 11)', login_time: '2026-06-11 19:45 PM', status: 'Success', fail_reason: '' },
      { id: 2, teacher_id: 'T1001', teacher_name: 'Dr. Priya Sharma', email: 'teacher@college.edu', device_name: 'Safari (iPhone 14)', login_time: '2026-06-11 18:22 PM', status: 'Failed', fail_reason: 'Device name mismatch' },
      { id: 3, teacher_id: 'ADM01', teacher_name: 'Admin Administrator', email: 'admin@college.edu', device_name: 'Chrome (macOS)', login_time: '2026-06-11 15:30 PM', status: 'Success', fail_reason: '' }
    ]
  },

  // Initialize Application
  async init() {
    console.log("PS: app.init() started");
    try {
      this.detectDeviceName();
      console.log("PS: detectDeviceName() succeeded");
    } catch (e) {
      console.error("PS: detectDeviceName() failed:", e);
    }

    try {
      this.fetchLocation();
      console.log("PS: fetchLocation() succeeded");
    } catch (e) {
      console.error("PS: fetchLocation() failed:", e);
    }

    try {
      this.setupDatePickers();
      console.log("PS: setupDatePickers() succeeded");
    } catch (e) {
      console.error("PS: setupDatePickers() failed:", e);
    }

    try {
      console.log("PS: testBackendConnection() starting");
      this.testBackendConnection();
      console.log("PS: testBackendConnection() started asynchronously");
    } catch (e) {
      console.error("PS: testBackendConnection() failed:", e);
    }

    // Session recovery
    try {
      const savedTeacher = localStorage.getItem('ps_teacher');
      console.log("PS: savedTeacher read from localStorage:", savedTeacher);
      if (savedTeacher) {
        try {
          this.state.teacher = JSON.parse(savedTeacher);
          console.log("PS: Recovered teacher session:", this.state.teacher);
          this.navigateTo('app-shell');
          this.switchPanel('home-panel');
          this.refreshData();
        } catch (e) {
          console.error("PS: Failed to parse saved teacher:", e);
          localStorage.removeItem('ps_teacher');
          this.navigateTo('login-view');
        }
      } else {
        console.log("PS: No saved session. Setting 2s timer for login transition...");
        // Transition from splash to login view after 2.0s
        setTimeout(() => {
          console.log("PS: Transition timer fired. Navigating to login-view...");
          this.navigateTo('login-view');
        }, 2000);
      }
    } catch (e) {
      console.error("PS: Session recovery failed:", e);
      this.navigateTo('login-view');
    }
  },

  // Ping Backend server
  async testBackendConnection() {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);
      const res = await fetch(`${this.apiUrl}/get_reports`, { signal: controller.signal });
      clearTimeout(timeoutId);
      if (res.ok) {
        this.simulatorMode = false;
        document.getElementById('offline-banner').style.display = 'none';
      } else {
        throw new Error();
      }
    } catch (e) {
      this.simulatorMode = true;
      document.getElementById('offline-banner').style.display = 'flex';
    }
  },

  toggleSimulatorMode() {
    this.simulatorMode = !this.simulatorMode;
    document.getElementById('offline-banner').style.display = this.simulatorMode ? 'flex' : 'none';
    this.showToast(this.simulatorMode ? 'Simulator mode enabled (Offline)' : 'Attempting to run online...');
    this.refreshData();
  },

  // View Navigation System
  navigateTo(viewId) {
    // Hide all view containers
    document.querySelectorAll('.view-container').forEach(el => {
      el.classList.remove('active');
    });
    document.getElementById('app-shell').classList.remove('active');

    // Show target view
    if (viewId === 'app-shell') {
      document.getElementById('app-shell').classList.add('active');
      const firstPanel = this.state.teacher.role === 'admin' ? 'home-panel' : 'home-panel';
      this.switchPanel(firstPanel);
    } else {
      const target = document.getElementById(viewId);
      target.classList.add('active');
      // Fade transition
      setTimeout(() => {
        target.style.opacity = 1;
        target.style.transform = 'translateY(0)';
      }, 50);
    }
    this.state.activeView = viewId;
  },

  // Navigation panel switcher (Dashboard Panels)
  switchPanel(panelId, element) {
    this.state.activePanel = panelId;
    
    // Hide all workspace view panels inside shell
    document.querySelectorAll('.shell-content > .view-container').forEach(el => {
      el.classList.remove('active');
    });

    // Show active panel
    const activeEl = document.getElementById(panelId);
    if (activeEl) {
      activeEl.classList.add('active');
      activeEl.style.opacity = 1;
      activeEl.style.transform = 'translateY(0)';
    }

    // Update Sidebar Navigation state
    document.querySelectorAll('.sidebar-link').forEach(link => {
      link.classList.remove('active');
    });
    if (element) {
      element.classList.add('active');
    } else {
      const match = document.querySelector(`.sidebar-link[data-target="${panelId}"]`);
      if (match) match.classList.add('active');
    }

    // Update Bottom Navigation state (Mobile view)
    document.querySelectorAll('.bottom-nav-tab').forEach(tab => {
      tab.classList.remove('active');
    });
    const bottomTab = document.querySelector(`.bottom-nav-tab[data-target="${panelId}"]`);
    if (bottomTab) bottomTab.classList.add('active');

    // Set mobile header title and back button
    const titleMap = {
      'home-panel': 'Dashboard',
      'add-report-panel': 'Add Report',
      'reports-panel': 'Reports List',
      'report-details-panel': 'Report Details',
      'search-student-panel': 'Student Search',
      'access-requests-panel': 'Access Requests',
      'login-history-panel': 'Login History',
      'notifications-panel': 'Notifications',
      'profile-panel': 'My Profile'
    };
    document.getElementById('mobile-page-title').innerText = titleMap[panelId] || 'PatrolSecure';
    
    // Manage mobile header back navigation button
    const rootPanels = ['home-panel', 'reports-panel', 'search-student-panel', 'profile-panel'];
    const backBtn = document.getElementById('mobile-back-btn');
    if (rootPanels.includes(panelId)) {
      backBtn.style.display = 'none';
    } else {
      backBtn.style.display = 'flex';
    }

    // Trigger loads/refresh based on panel selection
    if (panelId === 'home-panel') {
      this.refreshData();
    } else if (panelId === 'reports-panel') {
      this.fetchReports();
    } else if (panelId === 'access-requests-panel') {
      this.fetchAccessRequests();
    } else if (panelId === 'login-history-panel') {
      this.fetchLoginHistory();
    } else if (panelId === 'profile-panel') {
      this.state.editingProfile = false;
      document.getElementById('profile-info-display').style.display = 'block';
      document.getElementById('profile-edit-form').style.display = 'none';
      document.getElementById('profile-edit-icon').innerText = 'edit';
      this.fetchMyReportsCount();
    }
  },

  handleMobileBack() {
    const parentPanel = {
      'add-report-panel': 'home-panel',
      'report-details-panel': 'reports-panel',
      'access-requests-panel': 'home-panel',
      'login-history-panel': 'profile-panel',
      'notifications-panel': 'home-panel'
    };
    const target = parentPanel[this.state.activePanel] || 'home-panel';
    this.switchPanel(target);
  },

  openMobileNotifications() {
    this.switchPanel('notifications-panel');
  },

  // Toggle fields values
  togglePasswordVisibility(fieldId, element) {
    const input = document.getElementById(fieldId);
    const icon = element.querySelector('span');
    if (input.type === 'password') {
      input.type = 'text';
      icon.innerText = 'visibility';
    } else {
      input.type = 'password';
      icon.innerText = 'visibility_off';
    }
  },

  // Auto detect user browser specifications
  detectDeviceName() {
    const ua = navigator.userAgent;
    let device = 'Web Browser';
    
    if (ua.match(/chrome|chromium|crios/i)) {
      device = 'Chrome';
    } else if (ua.match(/firefox|fxios/i)) {
      device = 'Firefox';
    } else if (ua.match(/safari/i)) {
      device = 'Safari';
    } else if (ua.match(/opr\//i)) {
      device = 'Opera';
    } else if (ua.match(/edg/i)) {
      device = 'Edge';
    }
    
    let os = 'OS';
    if (ua.match(/android/i)) {
      os = 'Android';
    } else if (ua.match(/iphone|ipad|ipod/i)) {
      os = 'iOS Mobile';
    } else if (ua.match(/windows/i)) {
      os = 'Windows 11';
    } else if (ua.match(/macintosh/i)) {
      os = 'macOS';
    } else if (ua.match(/linux/i)) {
      os = 'Linux';
    }
    
    const formatted = `${device} (${os})`;
    document.getElementById('login-device').value = formatted;
    document.getElementById('signup-device').value = formatted;
  },

  // Browser Geolocation
  fetchLocation() {
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        position => {
          this.state.gps = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            status: 'active'
          };
          this.updateGpsChips();
        },
        error => {
          this.state.gps = { latitude: null, longitude: null, status: 'error' };
          this.updateGpsChips();
        },
        { enableHighAccuracy: true, timeout: 10000 }
      );
    } else {
      this.state.gps = { latitude: null, longitude: null, status: 'error' };
      this.updateGpsChips();
    }
  },

  updateGpsChips() {
    const states = {
      active: {
        class: 'gps-chip active',
        text: `Location: ${this.state.gps.latitude.toFixed(4)}° N, ${this.state.gps.longitude.toFixed(4)}° E`
      },
      error: {
        class: 'gps-chip error',
        text: 'Location unavailable — enable GPS'
      },
      loading: {
        class: 'gps-chip loading',
        text: 'Fetching location...'
      }
    };

    const current = states[this.state.gps.status];
    
    ['login-gps-chip', 'signup-gps-chip'].forEach(id => {
      const el = document.getElementById(id);
      if (el) {
        el.className = current.class;
        const dot = el.querySelector('.gps-dot');
        if (dot) dot.className = this.state.gps.status === 'loading' ? 'gps-dot loading' : 'gps-dot';
      }
    });

    ['login-gps-text', 'signup-gps-text'].forEach(id => {
      const el = document.getElementById(id);
      if (el) el.innerText = current.text;
    });
  },

  setupDatePickers() {
    // Set add patrol report date to current timestamp
    const now = new Date();
    // Format to local date time format (YYYY-MM-DDThh:mm)
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    
    const formatted = `${year}-${month}-${day}T${hours}:${minutes}`;
    document.getElementById('report-datetime').value = formatted;
  },

  // LOGIN REQUEST
  async handleLogin(event) {
    event.preventDefault();
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    const deviceName = document.getElementById('login-device').value;

    const submitBtn = document.getElementById('login-submit-btn');
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<div class="btn-loader"></div>';

    if (this.simulatorMode) {
      setTimeout(() => {
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span>SIGN IN</span><span class="material-icons">login</span>';
        
        // Mock Login logic
        const user = this.mockDb.teachers.find(t => t.email.toLowerCase() === email.toLowerCase());
        if (user) {
          // Success
          this.state.teacher = user;
          localStorage.setItem('ps_teacher', JSON.stringify(user));
          
          // Log login history
          this.mockDb.loginHistory.unshift({
            id: Date.now(),
            teacher_id: user.teacherId,
            teacher_name: user.name,
            email: user.email,
            device_name: deviceName,
            login_time: new Date().toLocaleString(),
            status: 'Success',
            fail_reason: ''
          });

          this.navigateTo('app-shell');
          this.showToast(`Logged in as ${user.name}`);
        } else {
          // 403 simulation mismatch scenario if it's admin@college.edu but on random device
          if (email.startsWith('request')) {
            this.showMismatchModal(email, deviceName);
          } else {
            // Failure
            this.showToast('Login credentials not found. Use simulator accounts like teacher@college.edu', 'error');
            this.mockDb.loginHistory.unshift({
              id: Date.now(),
              teacher_id: 'UNKNOWN',
              teacher_name: 'Unknown User',
              email: email,
              device_name: deviceName,
              login_time: new Date().toLocaleString(),
              status: 'Failed',
              fail_reason: 'Invalid email or password'
            });
          }
        }
      }, 1000);
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email,
          password,
          device_name: deviceName,
          latitude: this.state.gps.latitude,
          longitude: this.state.gps.longitude
        })
      });

      const body = await res.json();
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>SIGN IN</span><span class="material-icons">login</span>';

      if (res.ok) {
        this.state.teacher = body.teacher;
        localStorage.setItem('ps_teacher', JSON.stringify(body.teacher));
        this.navigateTo('app-shell');
        this.showToast(`Logged in successfully`);
        this.refreshData();
      } else if (res.status === 403) {
        this.showMismatchModal(email, deviceName, body.error || 'Device/location authorization issue.');
      } else {
        this.showToast(body.error || 'Login failed', 'error');
      }
    } catch (err) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>SIGN IN</span><span class="material-icons">login</span>';
      this.showToast('Network issue. Entering local simulator.', 'warning');
      this.simulatorMode = true;
      document.getElementById('offline-banner').style.display = 'flex';
      this.handleLogin(event); // Retry using simulator mode
    }
  },

  showMismatchModal(email, deviceName, errorMsg) {
    this.state.pendingAccessRequestData = { email, deviceName };
    document.getElementById('mismatch-message').innerText = errorMsg || 'Your current device or location does not match our registration system. Please file an access request.';
    document.getElementById('mismatch-modal').classList.add('active');
  },

  // SUBMIT ACCESS REQUEST
  async submitAccessRequest() {
    const data = this.state.pendingAccessRequestData;
    if (!data) return;

    this.closeModal('mismatch-modal');

    if (this.simulatorMode) {
      this.mockDb.accessRequests.unshift({
        id: Date.now(),
        email: data.email,
        device_name: data.deviceName,
        request_time: new Date().toLocaleString(),
        status: 'Pending'
      });
      this.showSuccessModal('Request Submitted', 'Access request submitted! Admin will review shortly.');
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/request_access`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: data.email,
          device_name: data.deviceName,
          latitude: this.state.gps.latitude,
          longitude: this.state.gps.longitude
        })
      });
      const body = await res.json();
      if (res.ok) {
        this.showSuccessModal('Request Submitted', 'Access request submitted! Admin will review shortly.');
      } else {
        this.showToast(body.error || 'Failed to submit request', 'error');
      }
    } catch (e) {
      this.showToast('Network error while requesting access', 'error');
    }
  },

  // SIGNUP REQUEST
  async handleSignup(event) {
    event.preventDefault();
    const name = document.getElementById('signup-name').value.trim();
    const teacherId = document.getElementById('signup-teacherid').value.trim();
    const email = document.getElementById('signup-email').value.trim();
    const phone = document.getElementById('signup-phone').value.trim();
    const department = document.getElementById('signup-department').value;
    const password = document.getElementById('signup-password').value;
    const deviceName = document.getElementById('signup-device').value;

    const submitBtn = document.getElementById('signup-submit-btn');
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<div class="btn-loader"></div>';

    if (this.simulatorMode) {
      setTimeout(() => {
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span>REGISTER NOW</span><span class="material-icons-outlined">how_to_reg</span>';
        
        // Add to simulated teacher list
        const newUser = {
          id: Date.now(), name, teacherId, email, phone, department, deviceName, role: 'teacher'
        };
        this.mockDb.teachers.push(newUser);
        
        // Submit simulated access request automatically
        this.mockDb.accessRequests.unshift({
          id: Date.now(),
          email: email,
          device_name: deviceName,
          request_time: new Date().toLocaleString(),
          status: 'Pending'
        });

        this.showSuccessModal('Registration Completed', 'Registration request submitted successfully! An administrator will review your device and location details to grant system access.');
        this.navigateTo('login-view');
      }, 1000);
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name,
          teacher_id: teacherId,
          email,
          phone,
          department,
          password,
          device_name: deviceName,
          latitude: this.state.gps.latitude,
          longitude: this.state.gps.longitude
        })
      });
      const body = await res.json();
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>REGISTER NOW</span><span class="material-icons-outlined">how_to_reg</span>';

      if (res.ok || res.status === 201) {
        this.showSuccessModal('Registration Completed', 'Registration request submitted successfully! An administrator will review your device and location details to grant system access.');
        this.navigateTo('login-view');
      } else {
        this.showToast(body.error || 'Registration failed', 'error');
      }
    } catch (err) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>REGISTER NOW</span><span class="material-icons-outlined">how_to_reg</span>';
      this.showToast('Server connection failed.', 'error');
    }
  },

  // SUBMIT REPORT SCREEN
  selectIssueType(type, element) {
    this.state.selectedIssueType = type;
    document.querySelectorAll('#issue-selector-grid .issue-option').forEach(el => {
      el.classList.remove('selected');
    });
    element.classList.add('selected');
  },

  async handleReportSubmit(event) {
    event.preventDefault();
    
    if (!this.state.selectedIssueType) {
      this.showToast('Please select an Issue Type', 'warning');
      return;
    }

    const studentName = document.getElementById('report-student-name').value.trim();
    const registerNumber = document.getElementById('report-student-reg').value.trim().toUpperCase();
    const department = document.getElementById('report-student-dept').value;
    const yearSection = document.getElementById('report-student-year').value;
    const location = document.getElementById('report-location').value.trim();
    const remarks = document.getElementById('report-remarks').value.trim();
    const dateTime = document.getElementById('report-datetime').value;

    const submitBtn = document.getElementById('report-submit-btn');
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<div class="btn-loader"></div>';

    const payload = {
      student_name: studentName,
      register_number: registerNumber,
      department: department,
      year_section: yearSection,
      issue_type: this.state.selectedIssueType,
      location: location,
      remarks: remarks,
      reported_by: this.state.teacher.teacherId,
      teacher_name: this.state.teacher.name,
      date_time: new Date(dateTime).toLocaleString()
    };

    if (this.simulatorMode) {
      setTimeout(() => {
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span>SUBMIT REPORT</span><span class="material-icons-outlined">send</span>';
        
        const newReport = {
          id: Date.now(),
          ...payload,
          status: 'Open'
        };
        this.mockDb.reports.unshift(newReport);
        
        // Notify simulation alert
        this.state.notifications.unshift({
          id: Date.now().toString(),
          title: 'New Patrol Report',
          message: `${this.state.teacher.name} submitted a new report for student ${registerNumber}`,
          type: 'info',
          time: new Date(),
          isRead: false
        });

        // Reset fields
        document.getElementById('report-form').reset();
        this.state.selectedIssueType = null;
        document.querySelectorAll('#issue-selector-grid .issue-option').forEach(el => el.classList.remove('selected'));
        this.setupDatePickers();

        this.showSuccessModal('Report Submitted', 'Patrol report has been recorded successfully.');
        this.switchPanel('home-panel');
      }, 800);
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/add_report`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const body = await res.json();
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>SUBMIT REPORT</span><span class="material-icons-outlined">send</span>';

      if (res.ok || res.status === 201) {
        document.getElementById('report-form').reset();
        this.state.selectedIssueType = null;
        document.querySelectorAll('#issue-selector-grid .issue-option').forEach(el => el.classList.remove('selected'));
        this.setupDatePickers();

        this.showSuccessModal('Report Submitted', 'Patrol report has been recorded successfully.');
        this.switchPanel('home-panel');
      } else {
        this.showToast(body.error || 'Failed to submit report', 'error');
      }
    } catch (e) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>SUBMIT REPORT</span><span class="material-icons-outlined">send</span>';
      this.showToast('Network error submitting report', 'error');
    }
  },

  // FETCH ALL REPORTS
  async fetchReports() {
    const listContainer = document.getElementById('reports-list-container');
    listContainer.innerHTML = '<div style="text-align: center; padding: 24px; color: var(--text-mut);"><div class="splash-loader" style="margin: 0 auto 12px auto; width: 30px; height: 30px;"></div>Loading reports...</div>';

    if (this.simulatorMode) {
      this.state.reports = [...this.mockDb.reports];
      this.filterReports();
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/get_reports`);
      if (res.ok) {
        const list = await res.json();
        this.state.reports = list;
        this.filterReports();
      } else {
        this.showToast('Failed to fetch reports from backend.', 'error');
      }
    } catch (e) {
      this.showToast('Connecting issues. Showing local database.', 'warning');
      this.simulatorMode = true;
      document.getElementById('offline-banner').style.display = 'flex';
      this.fetchReports();
    }
  },

  setReportsTabFilter(filter) {
    this.state.reportsTabFilter = filter;
    document.querySelectorAll('.tab-bar .tab-btn').forEach(btn => {
      btn.classList.remove('active');
    });
    document.getElementById(`reports-tab-${filter}`).classList.add('active');
    this.filterReports();
  },

  // FILTER & RENDER PATROL REPORTS LIST
  filterReports() {
    const searchVal = document.getElementById('reports-search-input').value.toLowerCase();
    const tabFilter = this.state.reportsTabFilter;

    let list = this.state.reports;

    // Filter by tab status
    if (tabFilter === 'open') {
      list = list.filter(r => r.status === 'Open');
    } else if (tabFilter === 'resolved') {
      list = list.filter(r => r.status === 'Resolved' || r.status === 'Closed');
    }

    // Filter by search query
    if (searchVal) {
      list = list.filter(r => 
        r.student_name.toLowerCase().includes(searchVal) ||
        r.register_number.toLowerCase().includes(searchVal) ||
        r.issue_type.toLowerCase().includes(searchVal)
      );
    }

    const container = document.getElementById('reports-list-container');
    if (list.length === 0) {
      container.innerHTML = '<div style="text-align: center; padding: 48px 20px; color: var(--text-mut); font-family: Rajdhani; font-size:16px;">No reports found</div>';
      return;
    }

    // Populate issue colors mapping
    const cMap = {
      'ID Card Missing': '#FFB800',
      'Uniform Issue': '#9B59B6',
      'Late Coming': '#00C2FF',
      'Mobile Usage': '#FF4D6A',
      'Misconduct': '#E67E22',
      'Restricted Area': '#8E44AD'
    };

    const iconMap = {
      'ID Card Missing': 'badge',
      'Uniform Issue': 'checkroom',
      'Late Coming': 'access_time',
      'Mobile Usage': 'smartphone',
      'Misconduct': 'warning_amber',
      'Restricted Area': 'location_off'
    };

    container.innerHTML = list.map(r => {
      const color = cMap[r.issue_type] || '#8BA3C0';
      const icon = iconMap[r.issue_type] || 'report_problem';
      const statusClass = r.status === 'Open' ? 'warning' : 'success';
      const formattedDate = this.formatDate(r.date_time);

      return `
        <div class="k-card hoverable" onclick="app.showReportDetails(${r.id})">
          <div class="report-card-inner">
            <div class="issue-icon-box" style="background: ${color}20; color: ${color};">
              <span class="material-icons-outlined">${icon}</span>
            </div>
            <div class="report-summary-text">
              <div class="report-summary-title">${escapeHtml(r.student_name)}</div>
              <div class="report-summary-subtitle" style="color: var(--accent); font-weight:600;">${escapeHtml(r.register_number)} • <span style="color: ${color}">${escapeHtml(r.issue_type)}</span></div>
              <div class="report-summary-meta">Location: ${escapeHtml(r.location)} • ${formattedDate}</div>
            </div>
            <span class="badge ${statusClass}">${r.status}</span>
          </div>
        </div>
      `;
    }).join('');
  },

  // SHOW INDIVIDUAL REPORT DETAILS
  showReportDetails(reportId) {
    const report = this.state.reports.find(r => r.id === reportId);
    if (!report) return;

    this.state.selectedReport = report;
    
    document.getElementById('detail-issue-type').innerText = report.issue_type;
    document.getElementById('detail-datetime').innerText = `Reported on ${this.formatDate(report.date_time)}`;
    document.getElementById('detail-student-name').innerText = report.student_name;
    document.getElementById('detail-student-reg').innerText = report.register_number;
    document.getElementById('detail-student-dept').innerText = report.department;
    document.getElementById('detail-student-year').innerText = report.year_section;
    document.getElementById('detail-location').innerText = report.location;
    document.getElementById('detail-date-time').innerText = this.formatDate(report.date_time);
    document.getElementById('detail-reported-by').innerText = report.teacher_name || report.reported_by;
    document.getElementById('detail-remarks').innerText = report.remarks || 'No remarks provided.';

    // Set badge style
    const badge = document.getElementById('detail-status-badge');
    badge.innerText = report.status;
    badge.className = `badge ${report.status === 'Open' ? 'warning' : (report.status === 'Resolved' ? 'success' : 'info')}`;

    // Color header based on issue
    const cMap = {
      'ID Card Missing': '#FFB800',
      'Uniform Issue': '#9B59B6',
      'Late Coming': '#00C2FF',
      'Mobile Usage': '#FF4D6A',
      'Misconduct': '#E67E22',
      'Restricted Area': '#8E44AD'
    };
    const color = cMap[report.issue_type] || '#FFB800';
    const hdr = document.getElementById('detail-header-card');
    hdr.style.borderColor = `${color}50`;
    hdr.style.background = `linear-gradient(135deg, ${color}22 0%, ${color}08 100%)`;
    hdr.querySelector('.icon').style.color = color;
    document.getElementById('detail-issue-type').style.color = color;

    // Highlight selected status button
    this.updateStatusSelectionButtons(report.status);

    this.switchPanel('report-details-panel');
  },

  updateStatusSelectionButtons(status) {
    document.querySelectorAll('#status-update-buttons .status-toggle-btn').forEach(btn => {
      btn.classList.remove('selected');
      if (btn.getAttribute('data-status') === status) {
        btn.classList.add('selected');
      }
    });
  },

  // UPDATE STATUS
  async updateReportStatus(newStatus) {
    const report = this.state.selectedReport;
    if (!report) return;

    this.updateStatusSelectionButtons(newStatus);

    if (this.simulatorMode) {
      report.status = newStatus;
      // Also update in mockDb
      const index = this.mockDb.reports.findIndex(r => r.id === report.id);
      if (index !== -1) this.mockDb.reports[index].status = newStatus;

      // Update badge
      const badge = document.getElementById('detail-status-badge');
      badge.innerText = newStatus;
      badge.className = `badge ${newStatus === 'Open' ? 'warning' : (newStatus === 'Resolved' ? 'success' : 'info')}`;

      this.showToast(`Status updated to ${newStatus}`);
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/update_report_status/${report.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      });
      if (res.ok) {
        report.status = newStatus;
        const badge = document.getElementById('detail-status-badge');
        badge.innerText = newStatus;
        badge.className = `badge ${newStatus === 'Open' ? 'warning' : (newStatus === 'Resolved' ? 'success' : 'info')}`;
        this.showToast(`Status updated to ${newStatus}`);
      } else {
        this.showToast('Failed to update status on server.', 'error');
      }
    } catch (e) {
      this.showToast('Network error updating status.', 'error');
    }
  },

  // SEARCH INDIVIDUAL STUDENT RECORD
  async handleStudentSearch(event) {
    event.preventDefault();
    const regNo = document.getElementById('search-student-reg').value.trim().toUpperCase();
    const submitBtn = document.getElementById('search-student-submit-btn');

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<div class="btn-loader"></div>';

    if (this.simulatorMode) {
      setTimeout(() => {
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span>GET STUDENT HISTORY</span><span class="material-icons-outlined">search</span>';
        
        const history = this.mockDb.reports.filter(r => r.register_number.toUpperCase() === regNo);
        this.renderStudentHistory(regNo, history);
      }, 600);
      return;
    }

    try {
      // Endpoint syntax in Flutter matches: get_reports, then filter by reg number or similar
      // Wait, Flutter calls: final res = await http.get(Uri.parse('${Url.Urls}/get_reports'));
      // And filters client-side or checks custom queries? Let's check:
      // "final res = await http.get(Uri.parse(url));" where url = '${Url.Urls}/student_history?reg_no=...' or similar.
      // Let's filter local state first, but if it is empty, fetch all reports and filter.
      const res = await fetch(`${this.apiUrl}/get_reports`);
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>GET STUDENT HISTORY</span><span class="material-icons-outlined">search</span>';

      if (res.ok) {
        const allReports = await res.json();
        const history = allReports.filter(r => r.register_number.toUpperCase() === regNo);
        this.renderStudentHistory(regNo, history);
      } else {
        this.showToast('Failed to retrieve history.', 'error');
      }
    } catch (e) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>GET STUDENT HISTORY</span><span class="material-icons-outlined">search</span>';
      this.showToast('Network issue fetching record.', 'error');
    }
  },

  renderStudentHistory(regNo, history) {
    const resultsDiv = document.getElementById('student-history-results');
    resultsDiv.style.display = 'block';

    if (history.length === 0) {
      document.getElementById('history-student-name').innerText = 'Unknown Student';
      document.getElementById('history-student-dept').innerText = '-';
      document.getElementById('history-student-year').innerText = '-';
      document.getElementById('history-student-count').innerText = '0';
      document.getElementById('history-student-count').style.color = 'var(--text-sec)';
      document.getElementById('student-history-list').innerHTML = '<div style="text-align: center; padding: 24px; color: var(--text-mut); font-family: Rajdhani;">Clean record! No violations found for this student.</div>';
      return;
    }

    const first = history[0];
    document.getElementById('history-student-name').innerText = first.student_name;
    document.getElementById('history-student-dept').innerText = first.department;
    document.getElementById('history-student-year').innerText = first.year_section;
    document.getElementById('history-student-count').innerText = history.length;
    
    const countColor = history.length >= 3 ? 'var(--error)' : 'var(--warning)';
    document.getElementById('history-student-count').style.color = countColor;

    // Disciplinary List render
    const listHtml = history.map(r => `
      <div class="k-card" style="border-left: 3px solid ${r.status === 'Open' ? 'var(--warning)' : 'var(--success)'}">
        <div class="report-card-inner">
          <div class="report-summary-text">
            <div class="report-summary-title" style="color: var(--accent);">${escapeHtml(r.issue_type)}</div>
            <div class="report-summary-subtitle">Location: ${escapeHtml(r.location)} • ${this.formatDate(r.date_time)}</div>
            <div class="remarks-box" style="margin-top: 8px; border:none; padding:0;">
              <p style="font-size: 13px; color: var(--text-sec);">${escapeHtml(r.remarks)}</p>
            </div>
            <div style="font-size: 10px; color: var(--text-mut); margin-top: 6px;">Reported by: ${escapeHtml(r.teacher_name)}</div>
          </div>
          <span class="badge ${r.status === 'Open' ? 'warning' : 'success'}">${r.status}</span>
        </div>
      </div>
    `).join('');

    document.getElementById('student-history-list').innerHTML = listHtml;
  },

  // FETCH ADMIN ACCESS REQUESTS
  async fetchAccessRequests() {
    const container = document.getElementById('admin-requests-list');
    container.innerHTML = '<div style="text-align: center; padding: 24px; color: var(--text-mut);"><div class="splash-loader" style="margin: 0 auto 12px auto; width: 30px; height: 30px;"></div>Loading access requests...</div>';

    if (this.simulatorMode) {
      this.state.accessRequests = [...this.mockDb.accessRequests];
      this.renderAccessRequests();
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/admin/access_requests`);
      if (res.ok) {
        this.state.accessRequests = await res.json();
        this.renderAccessRequests();
      } else {
        this.showToast('Failed to load requests.', 'error');
      }
    } catch (e) {
      this.showToast('Server issues. Accessing offline requests.', 'warning');
      this.simulatorMode = true;
      document.getElementById('offline-banner').style.display = 'flex';
      this.fetchAccessRequests();
    }
  },

  renderAccessRequests() {
    const container = document.getElementById('admin-requests-list');
    const reqs = this.state.accessRequests;
    
    // Update badge numbers
    const pendingCount = reqs.filter(r => r.status === 'Pending').length;
    const badgeSidebar = document.getElementById('sidebar-badge-requests');
    if (badgeSidebar) {
      if (pendingCount > 0) {
        badgeSidebar.innerText = pendingCount;
        badgeSidebar.style.display = 'flex';
      } else {
        badgeSidebar.style.display = 'none';
      }
    }

    if (reqs.length === 0) {
      container.innerHTML = '<div style="text-align: center; padding: 48px; color: var(--text-mut); font-family: Rajdhani;">No access requests found</div>';
      return;
    }

    container.innerHTML = reqs.map(r => {
      const color = r.status === 'Approved' ? 'success' : (r.status === 'Rejected' ? 'error' : 'warning');
      const timeStr = this.formatDate(r.request_time || r.created_at);

      return `
        <div class="k-card" style="border-color: ${r.status === 'Pending' ? 'var(--warning)' : 'var(--divider)'}">
          <div style="display:flex; justify-content:space-between; align-items:flex-start;">
            <div style="display:flex; gap:12px; align-items:center;">
              <div class="issue-icon-box" style="background: rgba(255, 184, 0, 0.1); color: var(--gold);">
                <span class="material-icons-outlined">person_add</span>
              </div>
              <div>
                <div style="font-weight: 700; font-size:14px; font-family: Rajdhani;">${escapeHtml(r.email)}</div>
                <div style="font-size:12px; color: var(--text-sec); margin-top:2px;">Device: ${escapeHtml(r.device_name)}</div>
                <div style="font-size:11px; color: var(--text-mut); margin-top:4px;">${timeStr}</div>
              </div>
            </div>
            <span class="badge ${color}">${r.status}</span>
          </div>

          ${r.status === 'Pending' ? `
            <div style="display:flex; gap:10px; margin-top: 14px;">
              <button class="btn-grad btn-danger" style="padding: 10px; font-size: 13px;" onclick="app.updateAccessRequest(${r.id}, 'Rejected')">REJECT</button>
              <button class="btn-grad" style="padding: 10px; font-size: 13px;" onclick="app.updateAccessRequest(${r.id}, 'Approved')">APPROVE</button>
            </div>
          ` : ''}
        </div>
      `;
    }).join('');
  },

  async updateAccessRequest(reqId, action) {
    if (this.simulatorMode) {
      const req = this.mockDb.accessRequests.find(r => r.id === reqId);
      if (req) {
        req.status = action;
        this.showToast(`Request ${action}`);
        this.fetchAccessRequests();
      }
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/admin/access_requests/${reqId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: action })
      });
      if (res.ok) {
        this.showToast(`Request ${action}`);
        this.fetchAccessRequests();
      } else {
        this.showToast('Failed to update request.', 'error');
      }
    } catch (e) {
      this.showToast('Network error updating request.', 'error');
    }
  },

  // FETCH LOGIN HISTORY LOGS
  async fetchLoginHistory() {
    const container = document.getElementById('admin-history-list');
    container.innerHTML = '<div style="text-align: center; padding: 24px; color: var(--text-mut);"><div class="splash-loader" style="margin: 0 auto 12px auto; width: 30px; height: 30px;"></div>Loading history...</div>';

    if (this.simulatorMode) {
      this.state.loginHistory = [...this.mockDb.loginHistory];
      this.renderLoginHistory();
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/login_history`);
      if (res.ok) {
        this.state.loginHistory = await res.json();
        this.renderLoginHistory();
      } else {
        this.showToast('Failed to load login history.', 'error');
      }
    } catch (e) {
      this.showToast('Server unavailable. Loading offline logs.', 'warning');
      this.simulatorMode = true;
      document.getElementById('offline-banner').style.display = 'flex';
      this.fetchLoginHistory();
    }
  },

  renderLoginHistory() {
    const container = document.getElementById('admin-history-list');
    const logs = this.state.loginHistory;

    if (logs.length === 0) {
      container.innerHTML = '<div style="text-align: center; padding: 48px; color: var(--text-mut); font-family: Rajdhani;">No login logs found</div>';
      return;
    }

    container.innerHTML = logs.map(l => {
      const isSuccess = l.status === 'Success';
      const color = isSuccess ? 'success' : 'error';
      const timeStr = this.formatDate(l.login_time || l.created_at);

      return `
        <div class="k-card" style="border-color: ${isSuccess ? 'var(--divider)' : 'rgba(255,77,106,0.3)'}">
          <div style="display:flex; justify-content:space-between; align-items:center;">
            <div style="display:flex; gap:12px; align-items:center;">
              <div class="issue-icon-box" style="background: ${isSuccess ? 'rgba(0, 224, 150, 0.1)' : 'rgba(255, 77, 106, 0.1)'}; color: ${isSuccess ? 'var(--success)' : 'var(--error)'};">
                <span class="material-icons-outlined">${isSuccess ? 'login' : 'gpp_bad'}</span>
              </div>
              <div>
                <div style="font-weight: 700; font-size:14px; font-family: Rajdhani;">${escapeHtml(l.teacher_name || 'Unknown User')}</div>
                <div style="font-size:12px; color: var(--text-sec); margin-top:2px;">ID: ${escapeHtml(l.teacher_id || 'N/A')} • Device: ${escapeHtml(l.device_name)}</div>
                ${l.fail_reason ? `<div style="font-size:11px; color: var(--error); margin-top:2px;">Reason: ${escapeHtml(l.fail_reason)}</div>` : ''}
                <div style="font-size:11px; color: var(--text-mut); margin-top:4px;">${timeStr}</div>
              </div>
            </div>
            <span class="badge ${color}">${l.status}</span>
          </div>
        </div>
      `;
    }).join('');
  },

  // NOTIFICATIONS SYSTEM
  populateNotifications() {
    const listContainer = document.getElementById('notifications-list-container');
    const notifs = this.state.notifications;

    const unreadCount = notifs.filter(n => !n.isRead).length;
    
    // Update badge UI indicators
    ['sidebar-badge-notifs', 'mobile-badge-notifs'].forEach(id => {
      const el = document.getElementById(id);
      if (el) {
        if (unreadCount > 0) {
          el.innerText = unreadCount;
          el.style.display = 'flex';
        } else {
          el.style.display = 'none';
        }
      }
    });

    if (notifs.length === 0) {
      listContainer.innerHTML = `
        <div style="text-align: center; padding: 48px 20px;">
          <span class="material-icons-outlined" style="font-size: 64px; color: var(--text-mut);">notifications_none</span>
          <h3 style="font-family: Rajdhani; font-size: 20px; font-weight: 700; margin-top: 16px;">No Notifications</h3>
          <p style="color: var(--text-mut); font-size: 14px;">You're all caught up!</p>
        </div>
      `;
      return;
    }

    const configs = {
      alert: { icon: 'security', color: 'var(--error)', tag: 'SECURITY ALERT' },
      warning: { icon: 'warning_amber', color: 'var(--warning)', tag: 'WARNING' },
      info: { icon: 'notifications', color: 'var(--accent)', tag: 'INFO' }
    };

    listContainer.innerHTML = notifs.map(n => {
      const cfg = configs[n.type] || configs.info;
      const readClass = n.isRead ? '' : 'unread';
      const timeStr = this.timeAgo(new Date(n.time));

      return `
        <div class="notification-card ${readClass}" onclick="app.markNotificationRead('${n.id}')">
          <div class="notification-icon-box" style="background: ${cfg.color}15; color: ${cfg.color};">
            <span class="material-icons-outlined">${cfg.icon}</span>
          </div>
          <div class="notification-details">
            <div class="notification-headline">
              <div class="notification-title">${escapeHtml(n.title)}</div>
              ${!n.isRead ? '<div class="notification-dot"></div>' : ''}
            </div>
            <p class="notification-msg">${escapeHtml(n.message)}</p>
            <div class="notification-meta">
              <span class="notification-tag ${n.type}">${cfg.tag}</span>
              <span class="notification-time">${timeStr}</span>
            </div>
          </div>
        </div>
      `;
    }).join('');
  },

  markNotificationRead(id) {
    const notif = this.state.notifications.find(n => n.id === id);
    if (notif) {
      notif.isRead = true;
      this.populateNotifications();
    }
  },

  markAllNotificationsRead() {
    this.state.notifications.forEach(n => n.isRead = true);
    this.populateNotifications();
    this.showToast('All notifications marked as read');
  },

  // DASHBOARD REFRESH DATA & RECENT ACTIVITY
  async refreshData() {
    if (!this.state.teacher) return;

    // Render static user elements
    const initial = this.state.teacher.name.charAt(0);
    document.getElementById('sidebar-avatar-char').innerText = initial;
    document.getElementById('profile-avatar-char').innerText = initial;
    document.getElementById('sidebar-user-name').innerText = this.state.teacher.name;
    document.getElementById('sidebar-user-id').innerText = `${this.state.teacher.department} • ${this.state.teacher.role}`;
    document.getElementById('welcome-name').innerText = `Hello, ${this.state.teacher.name}`;
    
    // Set view access controls
    const role = this.state.teacher.role;
    document.getElementById('welcome-role').innerText = `${role.toUpperCase()} PORTAL`;
    document.getElementById('sidebar-role-badge').innerText = `${role.toUpperCase()} PORTAL`;
    
    // Manage conditional UI options for Admin vs Teacher roles
    if (role === 'admin') {
      document.querySelectorAll('.teacher-only').forEach(el => el.style.display = 'none');
      document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'block');
      
      // Admin labels
      document.getElementById('stats-total-label').innerText = 'Total Reports';
      document.getElementById('stats-fourth-label').innerText = 'Failed Logins';
      document.getElementById('stats-fourth-icon').innerText = 'gpp_bad';
    } else {
      document.querySelectorAll('.teacher-only').forEach(el => el.style.display = 'block');
      document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'none');
      
      // Teacher labels
      document.getElementById('stats-total-label').innerText = 'My Reports';
      document.getElementById('stats-fourth-label').innerText = 'Violations Resolved';
      document.getElementById('stats-fourth-icon').innerText = 'done_all';
    }

    // Load recent reports & stats details
    let list = [];
    if (this.simulatorMode) {
      list = [...this.mockDb.reports];
    } else {
      try {
        const res = await fetch(`${this.apiUrl}/get_reports`);
        if (res.ok) list = await res.json();
      } catch (e) {
        this.simulatorMode = true;
        document.getElementById('offline-banner').style.display = 'flex';
        list = [...this.mockDb.reports];
      }
    }

    this.state.reports = list;

    // Render Stats
    let total = list.length;
    let unresolved = list.filter(r => r.status === 'Open').length;
    let resolved = list.filter(r => r.status === 'Resolved' || r.status === 'Closed').length;
    let fourthValue = 0;

    if (role === 'admin') {
      // Failed Logins count from history
      let hist = [];
      if (this.simulatorMode) {
        hist = this.mockDb.loginHistory;
      } else {
        try {
          const res = await fetch(`${this.apiUrl}/login_history`);
          if (res.ok) hist = await res.json();
        } catch (e) {}
      }
      fourthValue = hist.filter(h => h.status === 'Failed').length;
    } else {
      // My reports count & Resolved my reports
      const myReports = list.filter(r => r.reported_by === this.state.teacher.teacherId);
      total = myReports.length;
      unresolved = myReports.filter(r => r.status === 'Open').length;
      resolved = myReports.filter(r => r.status === 'Resolved' || r.status === 'Closed').length;
      fourthValue = resolved; // Violations Resolved
    }

    document.getElementById('stats-total-reports').innerText = total;
    document.getElementById('stats-open-reports').innerText = unresolved;
    document.getElementById('stats-resolved-reports').innerText = resolved;
    document.getElementById('stats-fourth-value').innerText = fourthValue;

    // Render 3 recent records
    const recent = list.slice(0, 3);
    const homeRecentList = document.getElementById('home-recent-list');
    
    if (recent.length === 0) {
      homeRecentList.innerHTML = '<div class="k-card" style="text-align: center; color: var(--text-mut); font-family: Rajdhani;">No recent activity.</div>';
    } else {
      const cMap = {
        'ID Card Missing': '#FFB800',
        'Uniform Issue': '#9B59B6',
        'Late Coming': '#00C2FF',
        'Mobile Usage': '#FF4D6A',
        'Misconduct': '#E67E22',
        'Restricted Area': '#8E44AD'
      };
      
      homeRecentList.innerHTML = recent.map(r => `
        <div class="k-card hoverable" onclick="app.showReportDetails(${r.id})">
          <div class="report-card-inner">
            <div class="report-summary-text">
              <div class="report-summary-title">${escapeHtml(r.student_name)} (${escapeHtml(r.register_number)})</div>
              <div class="report-summary-subtitle" style="color: ${cMap[r.issue_type] || 'var(--accent)'}; font-weight:600;">${escapeHtml(r.issue_type)}</div>
              <div class="report-summary-meta">Reported: ${this.formatDate(r.date_time)}</div>
            </div>
            <span class="badge ${r.status === 'Open' ? 'warning' : 'success'}">${r.status}</span>
          </div>
        </div>
      `).join('');
    }

    // Populate alerts / requests badge numbers
    if (role === 'admin') {
      this.fetchAccessRequests();
    }
    this.populateNotifications();
  },

  triggerFourthBoxAction() {
    if (this.state.teacher.role === 'admin') {
      this.switchPanel('login-history-panel');
    }
  },

  // MY REPORTS COUNT FOR PROFILE VIEW
  async fetchMyReportsCount() {
    let list = this.state.reports;
    if (list.length === 0) {
      if (this.simulatorMode) {
        list = [...this.mockDb.reports];
      } else {
        try {
          const res = await fetch(`${this.apiUrl}/get_reports`);
          if (res.ok) list = await res.json();
        } catch (e) {}
      }
    }
    const myCount = list.filter(r => r.reported_by === this.state.teacher.teacherId).length;
    document.getElementById('profile-stat-reports').innerText = myCount;
  },

  // PROFILE EDIT
  toggleProfileEdit() {
    this.state.editingProfile = !this.state.editingProfile;
    const infoDisplay = document.getElementById('profile-info-display');
    const editForm = document.getElementById('profile-edit-form');
    const editIcon = document.getElementById('profile-edit-icon');

    if (this.state.editingProfile) {
      infoDisplay.style.display = 'none';
      editForm.style.display = 'block';
      editIcon.innerText = 'close';
      
      // Populate fields
      document.getElementById('edit-profile-name').value = this.state.teacher.name;
      document.getElementById('edit-profile-phone').value = this.state.teacher.phone;
    } else {
      infoDisplay.style.display = 'block';
      editForm.style.display = 'none';
      editIcon.innerText = 'edit';
    }
  },

  async handleProfileSave(event) {
    event.preventDefault();
    const name = document.getElementById('edit-profile-name').value.trim();
    const phone = document.getElementById('edit-profile-phone').value.trim();
    const saveBtn = document.getElementById('profile-save-btn');

    saveBtn.disabled = true;
    saveBtn.innerHTML = '<div class="btn-loader"></div>';

    if (this.simulatorMode) {
      setTimeout(() => {
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<span>SAVE CHANGES</span><span class="material-icons-outlined">save</span>';
        
        // Update local state
        this.state.teacher.name = name;
        this.state.teacher.phone = phone;
        localStorage.setItem('ps_teacher', JSON.stringify(this.state.teacher));
        
        // Update display values
        document.getElementById('profile-val-name').innerText = name;
        document.getElementById('profile-val-phone').innerText = phone;
        document.getElementById('profile-details-name').innerText = name;
        
        this.toggleProfileEdit();
        this.showToast('Profile updated successfully');
        this.refreshData();
      }, 600);
      return;
    }

    try {
      const res = await fetch(`${this.apiUrl}/update_profile/${this.state.teacher.email}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, phone })
      });
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span>SAVE CHANGES</span><span class="material-icons-outlined">save</span>';

      if (res.ok) {
        this.state.teacher.name = name;
        this.state.teacher.phone = phone;
        localStorage.setItem('ps_teacher', JSON.stringify(this.state.teacher));
        
        document.getElementById('profile-val-name').innerText = name;
        document.getElementById('profile-val-phone').innerText = phone;
        document.getElementById('profile-details-name').innerText = name;

        this.toggleProfileEdit();
        this.showToast('Profile updated successfully');
        this.refreshData();
      } else {
        this.showToast('Failed to update profile.', 'error');
      }
    } catch (e) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span>SAVE CHANGES</span><span class="material-icons-outlined">save</span>';
      this.showToast('Network error updating profile.', 'error');
    }
  },

  // LOGOUT
  handleLogout() {
    localStorage.removeItem('ps_teacher');
    this.state.teacher = null;
    this.navigateTo('login-view');
    this.showToast('Logged out successfully');
  },

  // Dialog overlays UI
  showSuccessModal(title, msg) {
    document.getElementById('success-title').innerText = title;
    document.getElementById('success-message').innerText = msg;
    document.getElementById('success-modal').classList.add('active');
  },

  closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
  },

  // Helpers: Toast Alert Popup
  showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = 'toast';
    
    // Style variables for dynamic toasts
    const colors = {
      success: '#00E096',
      warning: '#FFB800',
      error: '#FF4D6A',
      info: '#00C2FF'
    };
    
    const icons = {
      success: 'check_circle',
      warning: 'warning',
      error: 'error',
      info: 'info'
    };

    const color = colors[type] || colors.success;
    const icon = icons[type] || icons.success;

    // Toast Inline styles matching theme
    Object.assign(toast.style, {
      position: 'fixed',
      bottom: '80px',
      left: '50%',
      transform: 'translateX(-50%) translateY(20px)',
      background: 'var(--card-bg)',
      color: 'var(--text-pri)',
      border: `1px solid ${color}40`,
      borderRadius: '12px',
      padding: '12px 20px',
      display: 'flex',
      align-items: 'center',
      gap: '10px',
      boxShadow: '0 8px 24px rgba(0,0,0,0.3)',
      backdropFilter: 'blur(12px)',
      zIndex: '2000',
      opacity: '0',
      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      fontFamily: 'Rajdhani',
      fontWeight: '600',
      fontSize: '14px',
      whiteSpace: 'nowrap'
    });

    toast.innerHTML = `
      <span class="material-icons" style="color: ${color}; font-size:18px;">${icon}</span>
      <span>${escapeHtml(message)}</span>
    `;

    document.body.appendChild(toast);
    
    // Animation trigger
    setTimeout(() => {
      toast.style.opacity = '1';
      toast.style.transform = 'translateX(-50%) translateY(0)';
    }, 10);

    // Fade out and remove
    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(-50%) translateY(-20px)';
      setTimeout(() => {
        toast.remove();
      }, 300);
    }, 3000);
  },

  formatDate(dateStr) {
    if (!dateStr) return '';
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return dateStr;
      
      const day = String(d.getDate()).padStart(2, '0');
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const year = d.getFullYear();
      const hours = String(d.getHours()).padStart(2, '0');
      const minutes = String(d.getMinutes()).padStart(2, '0');
      
      return `${day}/${month}/${year} ${hours}:${minutes}`;
    } catch (e) {
      return dateStr;
    }
  },

  timeAgo(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    let interval = Math.floor(seconds / 31536000);

    if (interval >= 1) return interval + 'y ago';
    interval = Math.floor(seconds / 2592000);
    if (interval >= 1) return interval + 'm ago';
    interval = Math.floor(seconds / 86400);
    if (interval >= 1) return interval + 'd ago';
    interval = Math.floor(seconds / 3600);
    if (interval >= 1) return interval + 'h ago';
    interval = Math.floor(seconds / 60);
    if (interval >= 1) return interval + 'm ago';
    return 'just now';
  }
};

// HTML Escaper helper to prevent XSS issues in mock lists
function escapeHtml(string) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return String(string).replace(/[&<>"']/g, function(m) { return map[m]; });
}

// Start app
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => app.init());
} else {
  app.init();
}
