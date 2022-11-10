(define-module (ebbot)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix utils)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages)
  #:use-module (gnu packages guile)
  #:use-module (guix build-system guile)
;;  #:use-module (guix build guile-build-system)  
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages texinfo)
  #:use-module (labsolns guile-oauth)
  #:use-module (json)

  )

(define-public ebbot
(package
  (name "ebbot")
  (version "0.1")
  (source (origin
           (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/mbcladwell/ebbot")
                      (commit "46317e992453e377a3bdcc04499623b443ea8e0f")))
                (sha256 (base32 "1h6w8znf4mza4ac93r2d3bzq5i293rr77h1kmsw3580fv92g971n"))));;anchor1
          ;;  (method url-fetch)
	  ;;  (uri "file:///home/mbc/projects/ebbot/ebbot-0.1.tar.gz")
	  ;;  ;;(uri (string-append "https://github.com/mbcladwell/ebbot/releases/download/v0.1/ebbot-0.1.tar.gz"))
	  ;; (sha256
          ;;  (base32
          ;;   "0g6ppkypr4628qgdlnvqsp10194dyrz8kwxbjiwayn2h258djkyh"))));;anchor1
  (build-system guile-build-system)
  (arguments `(
	       #:modules (((guix build guile-build-system)
			   #:select (target-guile-effective-version))
			  ,@%gnu-build-system-modules)
			 #:imported-modules ((guix build guile-build-system)
					     ,@%gnu-build-system-modules)
	     ;;  #:tests? #false ; there are none
			#:phases (modify-phases %standard-phases
    		       (add-after 'unpack 'patch-prefix
				  (lambda* (#:key inputs outputs #:allow-other-keys)
				    (let ((out  (assoc-ref outputs "out")))					  
				      (substitute* '("scripts/ebbot.sh" "scripts/format.sh" "scripts/init-acct.sh")
					(("ebbotstorepath")
					 out))
				      (substitute* '("scripts/ebbot.sh" "scripts/format.sh" "scripts/init-acct.sh")
					(("guileloadpath")
					 (string-append  out "/share/guile/site/3.0:"
							 (assoc-ref inputs "guile")  "/share/guile/site/3.0:"
							 (assoc-ref inputs "guile-json")  "/share/guile/site/3.0:"
							 (assoc-ref inputs "guile-oauth")  "/share/guile/site/3.0:"
							 (getenv "GUILE_LOAD_PATH") "\"")))
				      (substitute* '("scripts/ebbot.sh" "scripts/format.sh" "scripts/init-acct.sh")
					(("guileexecutable")
					 (string-append (assoc-ref inputs "guile") "/bin/guile")))
				      
				      (substitute* '("scripts/ebbot.sh" "scripts/format.sh" "scripts/init-acct.sh")
					(("guileloadcompiledpath")
					 (string-append  out "/lib/guile/3.0/site-ccache:"
							 (assoc-ref inputs "guile")  "/lib/guile/3.0/site-ccache:"
							 (assoc-ref inputs "guile-json")  "/lib/guile/3.0/site-ccache:"
							 (assoc-ref inputs "guile-oauth")  "/lib/guile/3.0/site-ccache:"
							 (getenv "GUILE_LOAD_COMPILED_PATH") "\""))))
				    #t))		    
		       (add-after 'patch-prefix 'make-dir
			 (lambda* (#:key outputs #:allow-other-keys)
			   (let* ((out  (assoc-ref outputs "out"))
				  (ebbot-dir (string-append out "/share/guile/site/3.0/ebbot"))
				  (mkdir-p ebbot-dir)
				  (dummy (copy-recursively "./ebbot" ebbot-dir))) 
			     #t)))
		       
			   (add-after 'make-dir 'make-bin-dir
				  (lambda* (#:key inputs outputs #:allow-other-keys)
				    (let* ((out (assoc-ref outputs "out"))
					   (bin-dir (string-append out "/bin"))
					   (scm  "/share/guile/site/3.0")
					   (go   "/lib/guile/3.0/site-ccache")
					   (all-files '("ebbot.sh" "format.sh" "init-acct.sh")))				      
				      (map (lambda (file)
					     (begin
					       (install-file (string-append "./scripts/" file) bin-dir)
					       (chmod (string-append bin-dir "/" file) #o555 ) read execute, no write
					       (wrap-program (string-append bin-dir "/" file)
							     `( "PATH" ":" prefix  (,bin-dir) )							     
							     `("GUILE_LOAD_PATH" prefix
							       (,(string-append out scm)
								))
							     `("GUILE_LOAD_COMPILED_PATH" prefix
							       (,(string-append out go)))
							     )))
					     all-files))					   					   	    
				      #t))

		       )))
  (inputs
    `(("guile" ,guile-3.0)
      ))
 ;; (inputs `(("guile" ,guile-3.0)))
  (propagated-inputs `( ("guile-json" ,guile-json-4) ("guile-oauth" ,guile-oauth)))
  (synopsis "Auto tweeter for educational tweets concerning propaganda")
  (description "Auto tweeter for educational tweets concerning propaganda")
  (home-page "www.build-a-bot.biz")
  (license license:gpl3+)))

ebbot

