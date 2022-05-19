(use-modules
  (guix packages)
  ((guix licenses) #:prefix license:)
  (guix download)
  (guix build-system gnu)
  (gnu packages)
  (gnu packages autotools)
  (gnu packages guile)
  (gnu packages guile-xyz)
  (gnu packages pkg-config)
  (gnu packages texinfo)
   (labsolns  guile-oauth)
    
  )

(package
  (name "ebbot")
  (version "0.1")
  (source (origin
           (method url-fetch)
	   (uri "file:///home/mbc/projects/ebbot/ebbot-0.1.tar.gz")
	  (sha256
           (base32
            "0ssi1wpaf7plaswqqjwigppsg5fyh99vdlb9kzl7c9lng89ndq1i"))
	  ))
  (build-system gnu-build-system)
  (arguments `(#:tests? #false ; there are none
			#:phases (modify-phases %standard-phases
    		       (add-after 'unpack 'patch-prefix
			       (lambda* (#:key inputs outputs #:allow-other-keys)
				 (substitute* '("scripts/ebbot.sh"
						                )
						(("abcdefgh")
						(assoc-ref outputs "out" )) )
					#t))		    
		       (add-before 'install 'make-scripts-dir
			       (lambda* (#:key outputs #:allow-other-keys)
				    (let* ((out  (assoc-ref outputs "out"))
					   (bin-dir (string-append out "/bin"))			      		   
					   )            				       
				      (install-file "scripts/ebbot.sh" bin-dir)
				       #t)))
			(add-after 'unpack 'make-dir
				   (lambda* (#:key outputs #:allow-other-keys)
				     (let* ((out  (assoc-ref outputs "out"))
					   (ebbot-dir (string-append out "/share/guile/site/3.0/ebbot"))
					   (mkdir-p ebbot-dir)
					   (dummy (copy-recursively "./ebbot" ebbot-dir))) 
				       #t)))
	       
		       (add-after 'install 'wrap-lnpg
				  (lambda* (#:key inputs outputs #:allow-other-keys)
				    (let* ((out (assoc-ref outputs "out"))
					   (bin-dir (string-append out "/bin"))
					    (scm  "/share/guile/site/3.0")
					    (go   "/lib/guile/3.0/site-ccache")
					   (dummy (chmod (string-append out "/bin/ebbot.sh") #o555 ))) ;;read execute, no write
				      (wrap-program (string-append out "/bin/ebbot.sh")
						    `( "PATH" ":" prefix  (,bin-dir) )
						     `("GUILE_LOAD_PATH" prefix
						       (,(string-append out scm)))						
						     `("GUILE_LOAD_COMPILED_PATH" prefix
						       (,(string-append out go)))
						     )		    
				      #t)))	       
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
  (license license:gpl3+))

