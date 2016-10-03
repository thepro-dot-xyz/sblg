/*	$Id$ */
/*
 * Copyright (c) 2016 Kristaps Dzonsons <kristaps@bsd.lv>,
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#include "config.h"

#include <sys/param.h>

#include <assert.h>
#include <expat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "extern.h"

static void
json_quoted(const char *cp, FILE *f)
{
	char	 c;

	fputc('"', f);
	while ('\0' != (c = *cp++))
		switch (c) {
		case ('"'):
		case ('\\'):
		case ('/'):
			fputc('\\', f);
			fputc(c, f);
			break;
		case ('\b'):
			fputs("\\b", f);
			break;
		case ('\f'):
			fputs("\\f", f);
			break;
		case ('\n'):
			fputs("\\n", f);
			break;
		case ('\r'):
			fputs("\\r", f);
			break;
		case ('\t'):
			fputs("\\t", f);
			break;
		default:
			fputc(c, f);
			break;
		}
	fputc('"', f);
}

static void
json_time(const char *key, time_t t, FILE *f)
{

	json_quoted(key, f);
	fputc(':', f);
	fprintf(f, "%lld", (long long)t);
}

static void
json_text(const char *key, const char *text, FILE *f)
{

	json_quoted(key, f);
	fputc(':', f);
	json_quoted(text, f);
}

static void
json_textxml(const char *key, 
	const char *text, const char *xml, FILE *f)
{

	json_quoted(key, f);
	fputc(':', f);
	fputc('{', f);
	if (NULL != text) {
		json_quoted("text", f);
		fputc(':', f);
		json_quoted(text, f);
		fputc(',', f);
	}
	json_quoted("xml", f);
	fputc(':', f);
	json_quoted(xml, f);
	fputc('}', f);
}

static void
json_textlist(const char *key, const char *list, FILE *f)
{
	char	*token, *string, *tofree;
	int	 first = 1;
	
	json_quoted("tags", f);
	fputc(':', f);
	fputc('[', f);

	if (NULL != list) {
		tofree = string = xstrdup(list);
		while (NULL != (token = strsep(&string, " "))) {
			if ('\0' == *token)
				continue;
			if ( ! first) 
				fputc(',', f);
			json_quoted(token, f);
			first = 0;
		}
		free(tofree);
	}
	fputc(']', f);
}

int
json(XML_Parser p, int sz, char *src[], const char *dst, enum asort asort)
{
	size_t		 j, sargsz;
	int		 i, fd, rc;
	FILE		*f;
	struct article	*sargs;

	rc = 0;
	fd = -1;
	f = NULL;

	sargs = NULL;
	sargsz = 0;

	for (i = 0; i < sz; i++)
		if ( ! grok(p, src[i], &sargs, &sargsz))
			goto out;

	if (ASORT_DATE == asort)
		qsort(sargs, sargsz, sizeof(struct article), datecmp);
	else if (ASORT_FILENAME == asort)
		qsort(sargs, sargsz, sizeof(struct article), filenamecmp);

	f = stdout;
	if (strcmp(dst, "-") && NULL == (f = fopen(dst, "w"))) {
		perror(dst);
		goto out;
	}

	fputc('{', f);
	json_quoted("articles", f);
	fputs(": [", f);

	for (j = 0; j < sargsz; j++) {
		fputc('{', f);
		json_text("src", sargs[j].src, f);
		fputc(',', f);
		json_text("base", sargs[j].base, f);
		fputc(',', f);
		json_text("stripbase", 
			sargs[j].stripbase, f);
		fputc(',', f);
		json_text("striplangbase", 
			sargs[j].striplangbase, f);
		fputc(',', f);
		json_time("time", sargs[j].time, f);
		fputc(',', f);
		json_textxml("title", 
			sargs[j].titletext, 
			sargs[j].title, f);
		fputc(',', f);
		json_textxml("aside", 
			sargs[j].asidetext, 
			sargs[j].aside, f);
		fputc(',', f);
		json_textxml("author", 
			sargs[j].authortext, 
			sargs[j].author, f);
		fputc(',', f);
		json_textxml("article", NULL,
			sargs[j].article, f);
		fputc(',', f);
		json_textlist("tags", 
			sargs[j].tags, f);
		fputc('}', f);
		if (j < sargsz - 1)
			fputc(',', f);
	}
	fputs("]}\n", f);

	rc = 1;
out:
	for (j = 0; j < sargsz; j++)
		article_free(&sargs[j]);
	if (NULL != f && stdout != f)
		fclose(f);

	free(sargs);
	return(rc);
}

