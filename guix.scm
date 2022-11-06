(define-module (labsolns ebbot)
#:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages texinfo)
  #:use-module (labsolns  guile-oauth)
  #:use-module (json)
  )

(define-public ebbot
(package
  (name "ebbot")
  (version "0.1")
  (source (origin
           (method url-fetch)
	   ;;(uri "file:///home/mbc/projects/ebbot/ebbot-0.1.tar.gz")
	   (uri (string-append "https://github.com/mbcladwell/ebbot/releases/download/v0.1/ebbot-0.1.tar.gz"))
	  (sha256
           (base32
             "1mv9fwyi325x40f40gr3dhyv1cldl3nx6c9d5x336iwk1z8adyzq"))));;anchor1
  (build-system gnu-build-system)
  (arguments `(#:tests? #false ; there are none
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
		       ;; (add-before 'install 'make-scripts-dir
		       ;; 	       (lambda* (#:key outputs #:allow-other-keys)
		       ;; 		    (let* ((out  (assoc-ref outputs "out"))
		       ;; 			   (bin-dir (string-append out "/bin"))
		       ;; 	      		   (dummy (install-file "scripts/format.sh" bin-dir))
		       ;; 			   )            				       
		       ;; 		      (install-file "scripts/ebbot.sh" bin-dir)
		       ;; 		       #t)))
			(add-after 'unpack 'make-dir
				   (lambda* (#:key outputs #:allow-other-keys)
				     (let* ((out  (assoc-ref outputs "out"))
					   (ebbot-dir (string-append out "/share/guile/site/3.0/ebbot"))
					   (mkdir-p ebbot-dir)
					   (dummy (copy-recursively "./ebbot" ebbot-dir))) 
				       #t)))

			   (add-after 'install 'make-bin-dir
				  (lambda* (#:key inputs outputs #:allow-other-keys)
				    (let* ((out (assoc-ref outputs "out"))
					   (bin-dir (string-append out "/bin"))
					   (scm  "/share/guile/site/3.0")
					   (go   "/lib/guile/3.0/site-ccache")
					   (all-files '("ebbot.sh" "format.sh" "init-acct.sh")))				      
				      (map (lambda (file)
					     (begin
					       (install-file (string-append "./scripts/" file) bin-dir)
					       (chmod (string-append bin-dir "/" file) #o555 ) ;;read execute, no write
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

		       ;; (add-after 'install 'wrap-ebbotsh
		       ;; 		  (lambda* (#:key inputs outputs #:allow-other-keys)
		       ;; 		    (let* ((out (assoc-ref outputs "out"))
		       ;; 			   (bin-dir (string-append out "/bin"))
		       ;; 			    (scm  "/share/guile/site/3.0")
		       ;; 			    (go   "/lib/guile/3.0/site-ccache")
		       ;; 			    (dummy (chmod (string-append out "/bin/ebbot.sh") #o555 ))
		       ;; 			    (dummy (chmod (string-append out "/share/guile/site/3.0/ebbot.scm") #o555 ))
		       ;; 			    ) ;;read execute, no write
		       ;; 		      (wrap-program (string-append out "/bin/ebbot.sh")
		       ;; 				    `( "PATH" ":" prefix  (,bin-dir) )
		       ;; 				     `("GUILE_LOAD_PATH" prefix
		       ;; 				       (,(string-append out scm)))						
		       ;; 				     `("GUILE_LOAD_COMPILED_PATH" prefix
		       ;; 				       (,(string-append out go)))
		       ;; 				     )		    
		       ;; 		      #t)))
		       ;; (add-after 'install 'wrap-formatsh
		       ;; 		  (lambda* (#:key inputs outputs #:allow-other-keys)
		       ;; 		    (let* ((out (assoc-ref outputs "out"))
		       ;; 			   (bin-dir (string-append out "/bin"))
		       ;; 			    (scm  "/share/guile/site/3.0")
		       ;; 			    (go   "/lib/guile/3.0/site-ccache")
		       ;; 			    (dummy (chmod (string-append out "/bin/format.sh") #o555 ))
		       ;; 			    (dummy (chmod (string-append out "/share/guile/site/3.0/ebbot/format.scm") #o555 ))
		       ;; 			    ) ;;read execute, no write
		       ;; 		      (wrap-program (string-append out "/bin/format.sh")
		       ;; 				    `( "PATH" ":" prefix  (,bin-dir) )
		       ;; 				     `("GUILE_LOAD_PATH" prefix
		       ;; 				       (,(string-append out scm)))						
		       ;; 				     `("GUILE_LOAD_COMPILED_PATH" prefix
		       ;; 				       (,(string-append out go)))
		       ;; 				     )		    
		       ;; 		      #t)))
		       

		       )))
  (native-inputs
    `(("autoconf" ,autoconf)
      ("automake" ,automake)
      ("pkg-config" ,pkg-config)
      ("texinfo" ,texinfo)))
  (inputs `(("guile" ,guile-3.0)))
  (propagated-inputs `( ("guile-json" ,guile-json-4) ("guile-oauth" ,guile-oauth)))
  (synopsis "Auto tweeter for educational tweets concerning propaganda")
  (description "Auto tweeter for educational tweets concerning propaganda")
  (home-page "www.build-a-bot.biz")
  (license license:gpl3+)))




