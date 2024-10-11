(define-module (ebbot mastodon) 
 #:use-module (ebbot env)
 #:use-module (web client)
 #:use-module (srfi srfi-19) ;; date time
 #:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
 #:use-module (srfi srfi-9)  ;;records
 #:use-module (web response)
 #:use-module (web request)
 #:use-module (oop goops) ;; class-of
 #:use-module (web uri)
 #:use-module (web client)
 #:use-module (web http)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 i18n)   ;; internationalization
 #:use-module (ice-9 popen)
 #:use-module (ice-9 regex) ;;list-matches
 #:use-module (ice-9 receive)	     
 #:use-module (ice-9 string-fun)  ;;string-replace-substring
 #:use-module (ice-9 pretty-print)
 #:use-module (json)
 #:use-module (rnrs bytevectors)
 #:use-module (ice-9 textual-ports)
 #:use-module (ebbot image)
 #:use-module (ebbot utilities)
 #:use-module (oauth oauth1)
 #:use-module (oauth oauth2)
 #:use-module (oauth oauth2 request)
 #:use-module (oauth oauth2 response)
 #:use-module (oauth utils)
 #:use-module (oauth request)
 #:use-module (oauth oauth1 client)
 #:use-module (oauth oauth1 utils)
 #:use-module (oauth oauth1 credentials)
 #:use-module (oauth oauth1 signature)
 
 #:export (
	   mast-post-toot-curl-recurse
	   mast-post-image-curl
	   mastodon-runner
	   main
	   ))

(define-record-type <response-token>
  (make-response-token token_type access_token)
  response-token?
  (token_type response-token-type)
  (access_token response-token-access-token))

;; (define *oauth-consumer-key* (@@ (ebbot env) *oauth-consumer-key*))
;; (define *oauth-consumer-secret* (@@ (ebbot env) *oauth-consumer-secret*))
;; (define *bearer-token* (@@ (ebbot env) *bearer-token*))  ;;this does not change
;; (define *oauth-access-token* (@@ (ebbot env) *oauth-access-token*))
;; (define *oauth-token-secret* (@@ (ebbot env) *oauth-token-secret*))
;; (define *client-id* (@@ (ebbot env) *client-id*))
;; (define *client-secret* (@@ (ebbot env) *client-secret*))

;; (define *data-dir* (@@ (ebbot env) *data-dir*))
;; (define *tweet-length* (@@ (ebbot env) *tweet-length*))

(define *oauth-consumer-key* #f)
(define *oauth-consumer-secret*  #f)
(define *bearer-token* #f)   ;;this does not change
(define *oauth-access-token* #f) 
(define *oauth-token-secret* #f)
(define *client-id* #f)
(define *client-secret* #f) 
(define *platform* #f)
(define *redirecturi* #f)
(define *data-dir* #f)
(define *tweet-length* #f) 
(define *gpg-key* "babweb@build-a-bot.biz")


(define oauth-response-token-record (make-response-token "bearer" *oauth-access-token* ))

(define (set-envs varlst)
  (begin
      (set! *oauth-consumer-key* (assoc-ref varlst "oauth-consumer-key"))
      (set! *oauth-consumer-secret* (assoc-ref varlst "oauth-consumer-secret"))
      (set! *bearer-token* (assoc-ref varlst "bearer-token"))
      (set! *oauth-access-token* (assoc-ref varlst "oauth-access-token"))
      (set! *oauth-token-secret* (assoc-ref varlst "oauth-token-secret"))
      (set! *client-id* (assoc-ref varlst "client-id"))
      (set! *client-secret* (assoc-ref varlst "client-secret"))
      (set! *redirecturi* (assoc-ref varlst "redirecturi"))
      (set! *platform* (assoc-ref varlst "platform"))
;;      (set! *data-dir* (assoc-ref varlst "data-dir"))
      (set! *tweet-length* (if (assoc-ref varlst "tweet-length")			    
			       (string->number (assoc-ref varlst "tweet-length"))
			       #f))))



;;curl -v -H 'Authorization: Bearer dFe6j-65kVREIqyJs7RSmn23GeFBEU4_Qb2Nln_z_Lw' -X POST -H 'Content-Type: multipart/form-data' https://mastodon.social/api/v2/media --form file='@/home/mbc/projects/babdata/archive/fakenewshist.jpeg'
(define (mast-post-image-curl i )
  (let*(
	(bearer (string-append "'Authorization: Bearer " *bearer-token* "'"))
	(image (string-append "file='@" i "'"))
	(out-file (get-rand-file-name "f" "txt"))
;;	(_ (pretty-print (string-append " *wd* in post-image-curl: " *working-dir*)))
;;	(_ (pretty-print (string-append "getcwd in post-image-curl: " (getcwd))))
	
	(command (string-append "curl -o " out-file " -X POST -H " bearer " -H 'Content-Type: multipart/form-data' https://mastodon.social/api/v2/media --form " image))
	(_ (system command))
	(_ (sleep 3))
	(p  (open-input-file out-file))
	(lst  (json-string->scm (get-string-all p)))
	(id (assoc-ref lst "id"))
	(_ (delete-file out-file))
      )
  id  ))


;; (define (mast-post-toot-curl t i)
;;   (let*((media-id (mast-post-image-curl i))
;; 	(media (string-append "' -F 'media_ids[]=" media-id "'"))
;; 	(pref "curl https://mastodon.social/api/v1/statuses -H 'Authorization: Bearer dFe6j-65kVREIqyJs7RSmn23GeFBEU4_Qb2Nln_z_Lw' -F 'status=")
;; 	(suff "'")
;; 	(command (string-append pref t media))
;; 	(_ (pretty-print command))
;; 	)
;;   (system command)  )
;;   )


;; (define (mast-post-toot-curl t i)
;;   (let*((media-id (mast-post-image-curl i))
;; 	(status (string-append " -F 'status=" t "'"))
;; 	(pref "curl https://mastodon.social/api/v1/statuses -H 'Authorization: Bearer dFe6j-65kVREIqyJs7RSmn23GeFBEU4_Qb2Nln_z_Lw' -F 'media_ids[]=")
;; 	(suff "'")
;; 	(command (string-append pref media-id status))
;; 	(_ (pretty-print command))
;; 	)
;;   (system command)  )
;;   )

;; curl -X POST \
;; 	-F 'client_id=your_client_id_here' \
;; 	-F 'client_secret=your_client_secret_here' \
;; 	-F 'redirect_uri=urn:ietf:wg:oauth:2.0:oob' \
;; 	-F 'grant_type=authorization_code' \
;; 	-F 'code=user_authzcode_here' \
;; 	-F 'scope=read write push' \
;; 	https://mastodon.example/oauth/token


(define (mastodon-get-access-post)
;;I already have the authorization code - now get access code
  (let* ((url "https://mastodon.social/oauth/token?")
	 (client-id *client-id*)
	 (suffix "&scope=write:statuses&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code")
(full-url (string-append url client-id suffix))
	 )
     (receive (response body)	  
	 (http-post full-url )
;;       (pretty-print (json-string->scm (utf8->string body))))
       (pretty-print (json-string->scm  body)))
    )

  )

(define (mast-post-toot-curl t i r)
  ;;t: text
  ;;i: media-id or #f
  ;;r: reply-id or #f
  (let*(;;(media-id (mast-post-image-curl i))
	(bearer (string-append "'Authorization: Bearer " *bearer-token* "'"))
	(media (if i (string-append "' --data-binary 'media_ids[]=" i ) ""))
	(reply (if r (string-append "' --data-binary 'in_reply_to_id=" r ) ""))
	(suffix "'")
	(out-file (get-rand-file-name "f" "txt"))
	(command (string-append "curl -o " out-file " https://mastodon.social/api/v1/statuses -H " bearer " --data-binary 'status=" t media reply suffix))
	(_ (system command))
	(_ (sleep 3))
	(p  (open-input-file out-file))
	(lst  (json-string->scm (get-string-all p)))
	;;      	(in (open-pipe*  OPEN_READ "curl" "-v" "-o" out-file "-H" bearer "-X" "POST" "-H" "'Content-Type: multipart/form-data'" "https://mastodon.social/api/v2/media" "--form" image))
	;;(_ (pretty-print lst))
	(id (assoc-ref lst "id"))
	(_ (delete-file out-file))
;;	(_ (pretty-print (string-append "post id: " id)))
	)
  id  ))

(define (mast-post-toot-curl-recurse lst reply-id media-id counter hashtags)
  ;;list of tweets to post
  ;;reply-id initially ""
  ;;counter initially 0; counter is needed to identify reply-id in first round and use media-id if exists
  ;;hashtags: "#uniparty #fakenews #misinformation #disinformation #propaganda"
  (if (null? (cdr lst))
	(mast-post-toot-curl (string-append (car lst) " " hashtags)  media-id reply-id);; last or only toot
      (if (eqv? counter 0) ;;the first toot with image and hashtags
	  (let* (;;(toot (string-append (car lst) " " hashtags))
		 (new-reply-id (mast-post-toot-curl (car lst) media-id reply-id))
		 (_ (set! counter (+ counter 1)))
		 )
	      ;; (pretty-print (cdr lst))
	      ;; (pretty-print (assoc-ref  (json-string->scm (utf8->string body)) "id_str"))
	       ;; (pretty-print  (json-string->scm (utf8->string body)))
	      ;; (pretty-print media-id)
	      ;; (pretty-print counter)

	    (mast-post-toot-curl-recurse  (cdr lst)  new-reply-id #f counter hashtags)		
	    )
	  (let* ((new-reply-id (mast-post-toot-curl (car lst) #f reply-id))
		 (_ (set! counter (+ counter 1))))
	    (mast-post-toot-curl-recurse  (cdr lst) new-reply-id #f counter hashtags)))))



;;guix shell -m manifest.scm -- guile -L . -L /home/mbc/projects/ebbot -e '(ebbot mastodon)' -s /home/mbc/projects/ebbot/ebbot/mastodon.scm /home/mbc/projects/babdata/ellul

(define (main args)
  (let* (;;(_ (get-envs))
	 (_ (set-envs (get-envs (cadr args))))
	 (_ (set! *data-dir* (cadr args)))
	 (_ (pretty-print (string-append "*data-dir*: " *data-dir*)))
	  (counter (get-counter *data-dir*))
	  (all-excerpts (get-all-excerpts-alist *data-dir*))
	  (max-id (assoc-ref (car all-excerpts) "id"))
	  (new-counter (if (= counter max-id) 0 (+ counter 1)))
          (entity (find-by-id all-excerpts new-counter))	 
	  (tweets (chunk-a-tweet (assoc-ref entity "content") *tweet-length*))
	  (hashtags (get-all-hashtags-string *data-dir*))
	  (media-directive (assoc-ref entity "image"))
	  (image-file (if (string=? media-directive "none") #f (get-image-file-name media-directive *data-dir*)))
	  (media-id (if image-file (mast-post-image-curl image-file ) #f))
	 ;; (_ (pretty-print media-id))
	  (_ (set-counter new-counter *data-dir*)))
 (pretty-print    (mast-post-toot-curl-recurse tweets #f media-id 0 hashtags))
))

