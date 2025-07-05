package jpacursortest;

import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jpacursortest.dto.TestDto;
import jpacursortest.infra.Repository;

import java.util.HashSet;
import java.util.List;

@Stateless
public class Application {

    private static final int ID_LIST_SIZE = 10000;

    @Inject
    private Repository repository;

    public void execute() {
        List<String> idList = repository.get().stream()
                .map(TestDto::getId)
                .limit(ID_LIST_SIZE)
                .toList();

        System.out.println("size of idList = " + idList.size());

        List<TestDto> findResult = repository.find(idList);
        System.out.println("size of findResult = " + findResult.size());

        List<TestDto> usingInResult = repository.findUsingIn(idList);
        System.out.println("size of usingInResult = " + usingInResult.size());

        List<TestDto> usingCursorResult = repository.findUsingCursor(idList);
        System.out.println("size of usingCursorResult = " + usingCursorResult.size());

        System.out.println("findResult == usingInResult : " + isSameList(findResult, usingInResult));
        System.out.println("findResult == usingCursorResult : " + isSameList(findResult, usingCursorResult));
    }

    private static <T> boolean isSameList(List<T> list1, List<T> list2) {
        return list1.size() == list2.size() && new HashSet<>(list1).containsAll(list2);
    }

}
